import Foundation
import Darwin
import llama

enum LlamaError: LocalizedError {
    case couldNotInitializeModel(path: String)
    case couldNotInitializeContext(path: String)

    var errorDescription: String? {
        switch self {
        case .couldNotInitializeModel(let path):
            return "Could not load model file at \(path). The GGUF may be incompatible or corrupted."
        case .couldNotInitializeContext(let path):
            return "Model loaded but context initialization failed for \(path). Try a smaller model or lower memory settings."
        }
    }
}

func llama_batch_clear(_ batch: inout llama_batch) {
    batch.n_tokens = 0
}

func llama_batch_add(_ batch: inout llama_batch, _ id: llama_token, _ pos: llama_pos, _ seq_ids: [llama_seq_id], _ logits: Bool) {
    batch.token   [Int(batch.n_tokens)] = id
    batch.pos     [Int(batch.n_tokens)] = pos
    batch.n_seq_id[Int(batch.n_tokens)] = Int32(seq_ids.count)
    for i in 0..<seq_ids.count {
        batch.seq_id[Int(batch.n_tokens)]![Int(i)] = seq_ids[i]
    }
    batch.logits  [Int(batch.n_tokens)] = logits ? 1 : 0

    batch.n_tokens += 1
}

actor LlamaContext {
    private enum SamplingStrategy {
        case chat
        case deterministic
    }

    private var model: OpaquePointer
    private var context: OpaquePointer
    private var vocab: OpaquePointer
    private var sampling: UnsafeMutablePointer<llama_sampler>
    private var activeSamplingStrategy: SamplingStrategy
    private var batch: llama_batch
    private var batchCapacity: Int32
    private var tokens_list: [llama_token]
    var is_done: Bool = false

    /// This variable is used to store temporarily invalid cchars
    private var temporary_invalid_cchars: [CChar]

    var n_len: Int32 = 512
    var n_cur: Int32 = 0
    var n_decode: Int32 = 0
    private let maxNewTokens: Int32 = 512
    private let minGenerationTokens: Int32 = 128
    private var generationEndPosition: Int32 = 0

    init(model: OpaquePointer, context: OpaquePointer) {
        self.model = model
        self.context = context
        self.tokens_list = []
        self.batchCapacity = max(512, Int32(llama_n_ctx(context)))
        self.batch = llama_batch_init(self.batchCapacity, 0, 1)
        self.temporary_invalid_cchars = []
        self.activeSamplingStrategy = .chat
        self.sampling = LlamaContext.makeSampler(strategy: .chat)
        vocab = llama_model_get_vocab(model)
    }

    deinit {
        llama_sampler_free(sampling)
        llama_batch_free(batch)
        llama_model_free(model)
        llama_free(context)
        llama_backend_free()
    }

    static func create_context(path: String) throws -> LlamaContext {
        llama_backend_init()
        var model_params = llama_model_default_params()

#if targetEnvironment(simulator)
        model_params.n_gpu_layers = 0
        print("Running on simulator, force use n_gpu_layers = 0")
#endif
        let model = llama_model_load_from_file(path, model_params)
        guard let model else {
            print("Could not load model at \(path)")
            throw LlamaError.couldNotInitializeModel(path: path)
        }

        let n_threads = max(1, min(8, ProcessInfo.processInfo.processorCount - 2))
        print("Using \(n_threads) threads")

        var ctx_params = llama_context_default_params()
        // Keep startup memory in a safer range for phones; users can tune up later.
        ctx_params.n_ctx = 2048
        ctx_params.n_threads       = Int32(n_threads)
        ctx_params.n_threads_batch = Int32(n_threads)

        let context = llama_init_from_model(model, ctx_params)
        guard let context else {
            print("Could not load context!")
            throw LlamaError.couldNotInitializeContext(path: path)
        }

        return LlamaContext(model: model, context: context)
    }

    func model_info() -> String {
        let result = UnsafeMutablePointer<Int8>.allocate(capacity: 256)
        result.initialize(repeating: Int8(0), count: 256)
        defer {
            result.deallocate()
        }

        // TODO: this is probably very stupid way to get the string from C

        let nChars = llama_model_desc(model, result, 256)
        let bufferPointer = UnsafeBufferPointer(start: result, count: Int(nChars))

        var SwiftString = ""
        for char in bufferPointer {
            SwiftString.append(Character(UnicodeScalar(UInt8(char))))
        }

        return SwiftString
    }

    func get_n_tokens() -> Int32 {
        return batch.n_tokens;
    }

    func completion_init(messages: [(role: String, content: String)], deterministic: Bool = false) {
        print("attempting to complete with \(messages.count) messages")

        is_done = false
        configureSampler(deterministic: deterministic)
        resetContextStateForNewCompletion()

        let promptText = applyChatTemplate(messages: messages)
        if promptText.isEmpty {
            is_done = true
            return
        }
        tokens_list = tokenize(text: promptText, add_bos: true)
        temporary_invalid_cchars = []

        if tokens_list.isEmpty {
            print("tokenization failed for prompt")
            is_done = true
            return
        }

        let n_ctx = Int(llama_n_ctx(context))
        let reserveForGeneration = Int(minGenerationTokens)
        if tokens_list.count >= n_ctx - reserveForGeneration {
            let keepPromptTokens = max(1, n_ctx - reserveForGeneration)
            tokens_list = Array(tokens_list.suffix(keepPromptTokens))
        }

        ensureBatchCapacity(requiredTokens: Int32(tokens_list.count + 1))

        let availableGenerationSlots = n_ctx - tokens_list.count - 1
        if availableGenerationSlots <= 0 {
            print("error: no room left in context window for generation")
            is_done = true
            return
        }

        n_len = min(maxNewTokens, Int32(availableGenerationSlots))
        generationEndPosition = Int32(tokens_list.count) + n_len
        let n_kv_req = tokens_list.count + Int(n_len)

        print("\n n_len = \(n_len), n_ctx = \(n_ctx), n_kv_req = \(n_kv_req)")

        if n_kv_req > n_ctx {
            print("error: n_kv_req > n_ctx, the required KV cache size is not big enough")
            is_done = true
            return
        }

        llama_batch_clear(&batch)

        for i1 in 0..<tokens_list.count {
            let i = Int(i1)
            llama_batch_add(&batch, tokens_list[i], Int32(i), [0], false)
        }
        batch.logits[Int(batch.n_tokens) - 1] = 1 // true

        if llama_decode(context, batch) != 0 {
            print("llama_decode() failed")
            is_done = true
            return
        }

        n_cur = batch.n_tokens
    }

    func completion_loop() -> String {
        var new_token_id: llama_token = 0
        new_token_id = llama_sampler_sample(sampling, context, batch.n_tokens - 1)

        // Guard against empty responses caused by EOS/control tokens as the first token.
        if n_decode == 0 {
            var attempts = 0
            while attempts < 24 {
                if llama_vocab_is_eog(vocab, new_token_id) {
                    attempts += 1
                    new_token_id = llama_sampler_sample(sampling, context, batch.n_tokens - 1)
                    continue
                }

                let firstPiece = token_to_piece(token: new_token_id)
                if !firstPiece.isEmpty {
                    break
                }

                attempts += 1
                new_token_id = llama_sampler_sample(sampling, context, batch.n_tokens - 1)
            }
        }

        if llama_vocab_is_eog(vocab, new_token_id) || n_cur >= generationEndPosition {
            print("\n")
            is_done = true
            let new_token_str = decodeBufferedTokenBytes(flush: true)
            temporary_invalid_cchars.removeAll()
            return new_token_str
        }

        let new_token_cchars = token_to_piece(token: new_token_id)
        temporary_invalid_cchars.append(contentsOf: new_token_cchars)
        let new_token_str = decodeBufferedTokenBytes(flush: false)
        print(new_token_str)
        llama_batch_clear(&batch)
        llama_batch_add(&batch, new_token_id, n_cur, [0], true)

        n_decode += 1
        n_cur    += 1

        if llama_decode(context, batch) != 0 {
            print("failed to evaluate llama!")
        }

        return new_token_str
    }

    private func decodeBufferedTokenBytes(flush: Bool) -> String {
        guard !temporary_invalid_cchars.isEmpty else { return "" }

        if let valid = String(validatingUTF8: temporary_invalid_cchars + [0]) {
            temporary_invalid_cchars.removeAll()
            return valid
        }

        if flush || temporary_invalid_cchars.count >= 12 {
            let bytes = temporary_invalid_cchars.map { UInt8(bitPattern: $0) }
            let lossy = String(decoding: bytes, as: UTF8.self)
            temporary_invalid_cchars.removeAll()
            return lossy
        }

        return ""
    }

    func get_n_decode() -> Int32 {
        return n_decode
    }

    func bench(pp: Int, tg: Int, pl: Int, nr: Int = 1) -> String {
        var pp_avg: Double = 0
        var tg_avg: Double = 0

        var pp_std: Double = 0
        var tg_std: Double = 0

        for _ in 0..<nr {
            // bench prompt processing

            llama_batch_clear(&batch)

            let n_tokens = pp

            for i in 0..<n_tokens {
                llama_batch_add(&batch, 0, Int32(i), [0], false)
            }
            batch.logits[Int(batch.n_tokens) - 1] = 1 // true

            let t_pp_start = DispatchTime.now().uptimeNanoseconds / 1000;

            if llama_decode(context, batch) != 0 {
                print("llama_decode() failed during prompt")
            }
            llama_synchronize(context)

            let t_pp_end = DispatchTime.now().uptimeNanoseconds / 1000;

            // bench text generation

            let t_tg_start = DispatchTime.now().uptimeNanoseconds / 1000;

            for i in 0..<tg {
                llama_batch_clear(&batch)

                for j in 0..<pl {
                    llama_batch_add(&batch, 0, Int32(i), [Int32(j)], true)
                }

                if llama_decode(context, batch) != 0 {
                    print("llama_decode() failed during text generation")
                }
                llama_synchronize(context)
            }

            let t_tg_end = DispatchTime.now().uptimeNanoseconds / 1000;

            let t_pp = Double(t_pp_end - t_pp_start) / 1000000.0
            let t_tg = Double(t_tg_end - t_tg_start) / 1000000.0

            let speed_pp = Double(pp)    / t_pp
            let speed_tg = Double(pl*tg) / t_tg

            pp_avg += speed_pp
            tg_avg += speed_tg

            pp_std += speed_pp * speed_pp
            tg_std += speed_tg * speed_tg

            print("pp \(speed_pp) t/s, tg \(speed_tg) t/s")
        }

        pp_avg /= Double(nr)
        tg_avg /= Double(nr)

        if nr > 1 {
            pp_std = sqrt(pp_std / Double(nr - 1) - pp_avg * pp_avg * Double(nr) / Double(nr - 1))
            tg_std = sqrt(tg_std / Double(nr - 1) - tg_avg * tg_avg * Double(nr) / Double(nr - 1))
        } else {
            pp_std = 0
            tg_std = 0
        }

        let model_desc     = model_info();
        let model_size     = String(format: "%.2f GiB", Double(llama_model_size(model)) / 1024.0 / 1024.0 / 1024.0);
        let model_n_params = String(format: "%.2f B", Double(llama_model_n_params(model)) / 1e9);
        let backend        = "Metal";
        let pp_avg_str     = String(format: "%.2f", pp_avg);
        let tg_avg_str     = String(format: "%.2f", tg_avg);
        let pp_std_str     = String(format: "%.2f", pp_std);
        let tg_std_str     = String(format: "%.2f", tg_std);

        var result = ""

        result += String("| model | size | params | backend | test | t/s |\n")
        result += String("| --- | --- | --- | --- | --- | --- |\n")
        result += String("| \(model_desc) | \(model_size) | \(model_n_params) | \(backend) | pp \(pp) | \(pp_avg_str) ± \(pp_std_str) |\n")
        result += String("| \(model_desc) | \(model_size) | \(model_n_params) | \(backend) | tg \(tg) | \(tg_avg_str) ± \(tg_std_str) |\n")

        return result;
    }

    func clear() {
        is_done = true
        n_decode = 0
        n_cur = 0
        tokens_list.removeAll()
        temporary_invalid_cchars.removeAll()
        llama_sampler_reset(sampling)
        let memory = llama_get_memory(context)
        llama_memory_clear(memory, false)
    }

    private static func makeSampler(strategy: SamplingStrategy) -> UnsafeMutablePointer<llama_sampler> {
        let sparams = llama_sampler_chain_default_params()
        guard let chain = llama_sampler_chain_init(sparams) else {
            fatalError("Failed to initialize llama sampler chain")
        }

        switch strategy {
        case .chat:
            llama_sampler_chain_add(chain, llama_sampler_init_top_k(40))
            llama_sampler_chain_add(chain, llama_sampler_init_top_p(0.90, 1))
            llama_sampler_chain_add(chain, llama_sampler_init_min_p(0.05, 1))
            llama_sampler_chain_add(chain, llama_sampler_init_temp(0.70))
            llama_sampler_chain_add(chain, llama_sampler_init_dist(UInt32.random(in: 1...UInt32.max)))
        case .deterministic:
            llama_sampler_chain_add(chain, llama_sampler_init_greedy())
        }

        return chain
    }

    private func configureSampler(deterministic: Bool) {
        let desiredStrategy: SamplingStrategy = deterministic ? .deterministic : .chat
        if desiredStrategy == activeSamplingStrategy {
            llama_sampler_reset(sampling)
            return
        }

        llama_sampler_free(sampling)
        sampling = LlamaContext.makeSampler(strategy: desiredStrategy)
        activeSamplingStrategy = desiredStrategy
    }

    private func resetContextStateForNewCompletion() {
        n_decode = 0
        n_cur = 0
        generationEndPosition = 0
        temporary_invalid_cchars.removeAll(keepingCapacity: true)
        tokens_list.removeAll(keepingCapacity: true)
        let memory = llama_get_memory(context)
        llama_memory_clear(memory, false)
    }

    private func tokenize(text: String, add_bos: Bool) -> [llama_token] {
        let utf8Count = text.utf8.count
        let n_tokens = utf8Count + (add_bos ? 1 : 0) + 1
        var tokens = UnsafeMutablePointer<llama_token>.allocate(capacity: n_tokens)
        var tokenCount = llama_tokenize(vocab, text, Int32(utf8Count), tokens, Int32(n_tokens), add_bos, true)

        if tokenCount < 0 {
            tokens.deallocate()
            let required = Int(-tokenCount)
            tokens = UnsafeMutablePointer<llama_token>.allocate(capacity: required)
            tokenCount = llama_tokenize(vocab, text, Int32(utf8Count), tokens, Int32(required), add_bos, true)
            if tokenCount < 0 {
                tokens.deallocate()
                return []
            }
        }

        var swiftTokens: [llama_token] = []
        for i in 0..<tokenCount {
            swiftTokens.append(tokens[Int(i)])
        }

        tokens.deallocate()

        return swiftTokens
    }

    private func ensureBatchCapacity(requiredTokens: Int32) {
        guard requiredTokens > batchCapacity else { return }
        llama_batch_free(batch)
        batchCapacity = requiredTokens
        batch = llama_batch_init(batchCapacity, 0, 1)
    }

    /// - note: The result does not contain null-terminator
    private func token_to_piece(token: llama_token) -> [CChar] {
        let result = UnsafeMutablePointer<Int8>.allocate(capacity: 8)
        result.initialize(repeating: Int8(0), count: 8)
        defer {
            result.deallocate()
        }
        let nTokens = llama_token_to_piece(vocab, token, result, 8, 0, false)

        if nTokens < 0 {
            let newResult = UnsafeMutablePointer<Int8>.allocate(capacity: Int(-nTokens))
            newResult.initialize(repeating: Int8(0), count: Int(-nTokens))
            defer {
                newResult.deallocate()
            }
            let nNewTokens = llama_token_to_piece(vocab, token, newResult, -nTokens, 0, false)
            let bufferPointer = UnsafeBufferPointer(start: newResult, count: Int(nNewTokens))
            return Array(bufferPointer)
        } else {
            let bufferPointer = UnsafeBufferPointer(start: result, count: Int(nTokens))
            return Array(bufferPointer)
        }
    }

    private func applyChatTemplate(messages: [(role: String, content: String)]) -> String {
        if messages.isEmpty {
            return ""
        }

        let fallbackPrompt = messages
            .map { "\($0.role): \($0.content)" }
            .joined(separator: "\n")

        guard let template = llama_model_chat_template(model, nil) else {
            return fallbackPrompt
        }

        var rolePtrs: [UnsafeMutablePointer<CChar>] = []
        var contentPtrs: [UnsafeMutablePointer<CChar>] = []
        var cMessages: [llama_chat_message] = []

        for message in messages {
            guard
                let rolePtr = strdup(message.role),
                let contentPtr = strdup(message.content)
            else {
                continue
            }
            rolePtrs.append(rolePtr)
            contentPtrs.append(contentPtr)
            cMessages.append(
                llama_chat_message(
                    role: UnsafePointer(rolePtr),
                    content: UnsafePointer(contentPtr)
                )
            )
        }

        if cMessages.isEmpty {
            return fallbackPrompt
        }

        defer {
            for ptr in rolePtrs {
                free(ptr)
            }
            for ptr in contentPtrs {
                free(ptr)
            }
        }

        let estimatedChars = max(4096, messages.reduce(0) { partial, message in
            partial + message.content.utf8.count + 24
        } * 4)
        var formatted = [CChar](repeating: 0, count: estimatedChars)
        var formattedLen = cMessages.withUnsafeMutableBufferPointer { msgBuffer in
            formatted.withUnsafeMutableBufferPointer { formattedBuffer in
                llama_chat_apply_template(
                    template,
                    msgBuffer.baseAddress,
                    msgBuffer.count,
                    true,
                    formattedBuffer.baseAddress,
                    Int32(formattedBuffer.count)
                )
            }
        }

        if formattedLen < 0 {
            return fallbackPrompt
        }

        if Int(formattedLen) >= formatted.count {
            formatted = [CChar](repeating: 0, count: Int(formattedLen) + 1)
            formattedLen = cMessages.withUnsafeMutableBufferPointer { msgBuffer in
                formatted.withUnsafeMutableBufferPointer { formattedBuffer in
                    llama_chat_apply_template(
                        template,
                        msgBuffer.baseAddress,
                        msgBuffer.count,
                        true,
                        formattedBuffer.baseAddress,
                        Int32(formattedBuffer.count)
                    )
                }
            }
        }

        if formattedLen < 0 {
            return fallbackPrompt
        }

        let promptBytes = formatted.prefix(Int(formattedLen)).map { UInt8(bitPattern: $0) }
        return String(bytes: promptBytes, encoding: .utf8) ?? fallbackPrompt
    }
}
