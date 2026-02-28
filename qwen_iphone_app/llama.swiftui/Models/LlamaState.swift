import Foundation
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct Model: Identifiable {
    var id = UUID()
    var name: String
    var url: String
    var filename: String
    var status: String?
}

enum ChatRole: String, Codable {
    case user
    case assistant
}

struct ChatMessage: Identifiable, Codable {
    let id: UUID
    let role: ChatRole
    var text: String
    let createdAt: Date

    init(id: UUID = UUID(), role: ChatRole, text: String, createdAt: Date = Date()) {
        self.id = id
        self.role = role
        self.text = text
        self.createdAt = createdAt
    }
}

struct ChatThread: Identifiable, Codable {
    let id: UUID
    var title: String
    var messages: [ChatMessage]
    var memoryNotes: [String]
    let createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String = "New Chat",
        messages: [ChatMessage] = [],
        memoryNotes: [String] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.messages = messages
        self.memoryNotes = memoryNotes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var preview: String {
        if let latest = messages.last(where: { !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) {
            return latest.text
        }
        return "No messages yet"
    }
}

private struct ChatStore: Codable {
    var threads: [ChatThread]
    var activeThreadID: UUID?
    var globalMemoryNotes: [String]
}

struct ThemeRGBA: Codable, Equatable {
    var r: Double
    var g: Double
    var b: Double
    var a: Double

    init(_ r: Double, _ g: Double, _ b: Double, _ a: Double = 1.0) {
        self.r = r
        self.g = g
        self.b = b
        self.a = a
    }

    var color: Color {
        Color(red: r, green: g, blue: b, opacity: a)
    }

    static func from(_ color: Color) -> ThemeRGBA {
#if canImport(UIKit)
        let uiColor = UIColor(color)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        if uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            return ThemeRGBA(Double(red), Double(green), Double(blue), Double(alpha))
        }

        var white: CGFloat = 0
        if uiColor.getWhite(&white, alpha: &alpha) {
            return ThemeRGBA(Double(white), Double(white), Double(white), Double(alpha))
        }
#endif
        return ThemeRGBA(0.0, 0.0, 0.0, 1.0)
    }
}

enum ThemePreset: String, Codable, CaseIterable, Identifiable {
    case blackGold
    case abyssTeal
    case emberSlate
    case noirEmerald

    var id: String { rawValue }

    var title: String {
        switch self {
        case .blackGold:
            return "Black & Gold"
        case .abyssTeal:
            return "Abyss Teal"
        case .emberSlate:
            return "Ember Slate"
        case .noirEmerald:
            return "Noir Emerald"
        }
    }
}

struct ChatTheme: Codable, Equatable {
    var preset: ThemePreset?
    var accent: ThemeRGBA
    var backgroundTop: ThemeRGBA
    var backgroundBottom: ThemeRGBA
    var panel: ThemeRGBA
    var userBubble: ThemeRGBA
    var assistantBubble: ThemeRGBA
    var userText: ThemeRGBA
    var assistantText: ThemeRGBA
    var bubbleCornerRadius: Double
    var inputCornerRadius: Double
    var fontScale: Double

    static func preset(_ preset: ThemePreset) -> ChatTheme {
        switch preset {
        case .blackGold:
            return ChatTheme(
                preset: .blackGold,
                accent: ThemeRGBA(0.88, 0.72, 0.24),
                backgroundTop: ThemeRGBA(0.01, 0.01, 0.01),
                backgroundBottom: ThemeRGBA(0.11, 0.09, 0.05),
                panel: ThemeRGBA(0.08, 0.08, 0.09),
                userBubble: ThemeRGBA(0.88, 0.72, 0.24),
                assistantBubble: ThemeRGBA(0.08, 0.08, 0.09),
                userText: ThemeRGBA(0.05, 0.05, 0.05),
                assistantText: ThemeRGBA(0.95, 0.95, 0.95),
                bubbleCornerRadius: 16,
                inputCornerRadius: 14,
                fontScale: 1.0
            )
        case .abyssTeal:
            return ChatTheme(
                preset: .abyssTeal,
                accent: ThemeRGBA(0.10, 0.84, 0.74),
                backgroundTop: ThemeRGBA(0.01, 0.03, 0.05),
                backgroundBottom: ThemeRGBA(0.04, 0.10, 0.12),
                panel: ThemeRGBA(0.06, 0.11, 0.13),
                userBubble: ThemeRGBA(0.13, 0.79, 0.72),
                assistantBubble: ThemeRGBA(0.07, 0.15, 0.18),
                userText: ThemeRGBA(0.04, 0.05, 0.05),
                assistantText: ThemeRGBA(0.90, 0.97, 0.97),
                bubbleCornerRadius: 18,
                inputCornerRadius: 15,
                fontScale: 1.0
            )
        case .emberSlate:
            return ChatTheme(
                preset: .emberSlate,
                accent: ThemeRGBA(0.95, 0.42, 0.23),
                backgroundTop: ThemeRGBA(0.05, 0.04, 0.05),
                backgroundBottom: ThemeRGBA(0.16, 0.10, 0.08),
                panel: ThemeRGBA(0.14, 0.10, 0.10),
                userBubble: ThemeRGBA(0.92, 0.41, 0.25),
                assistantBubble: ThemeRGBA(0.15, 0.12, 0.12),
                userText: ThemeRGBA(0.07, 0.04, 0.04),
                assistantText: ThemeRGBA(0.97, 0.92, 0.91),
                bubbleCornerRadius: 17,
                inputCornerRadius: 14,
                fontScale: 1.0
            )
        case .noirEmerald:
            return ChatTheme(
                preset: .noirEmerald,
                accent: ThemeRGBA(0.23, 0.88, 0.58),
                backgroundTop: ThemeRGBA(0.01, 0.04, 0.03),
                backgroundBottom: ThemeRGBA(0.03, 0.11, 0.08),
                panel: ThemeRGBA(0.05, 0.11, 0.09),
                userBubble: ThemeRGBA(0.24, 0.79, 0.53),
                assistantBubble: ThemeRGBA(0.05, 0.13, 0.10),
                userText: ThemeRGBA(0.04, 0.06, 0.05),
                assistantText: ThemeRGBA(0.92, 0.98, 0.94),
                bubbleCornerRadius: 16,
                inputCornerRadius: 14,
                fontScale: 1.0
            )
        }
    }
}

enum ThemeColorSlot: String, CaseIterable, Identifiable {
    case accent
    case backgroundTop
    case backgroundBottom
    case panel
    case userBubble
    case assistantBubble
    case userText
    case assistantText

    var id: String { rawValue }

    var title: String {
        switch self {
        case .accent:
            return "Accent"
        case .backgroundTop:
            return "Background Top"
        case .backgroundBottom:
            return "Background Bottom"
        case .panel:
            return "Panels"
        case .userBubble:
            return "User Bubble"
        case .assistantBubble:
            return "Assistant Bubble"
        case .userText:
            return "User Text"
        case .assistantText:
            return "Assistant Text"
        }
    }
}

@MainActor
class LlamaState: ObservableObject {
    @Published var messageLog = ""
    @Published var cacheCleared = false

    @Published var isLoadingModel = false
    @Published var loadingModelName = ""
    @Published var isModelLoaded = false
    @Published var currentModelName = "No model loaded"

    @Published var isGenerating = false
    @Published var draft = ""
    @Published var useNoThinkByDefault = true

    @Published var downloadedModels: [Model] = []
    @Published var undownloadedModels: [Model] = []

    @Published var threads: [ChatThread] = []
    @Published var activeThreadID: UUID?
    @Published var activeThreadTitle = "New Chat"
    @Published var messages: [ChatMessage] = []
    @Published var globalMemoryNotes: [String] = []
    @Published var theme: ChatTheme = .preset(.blackGold) {
        didSet {
            persistThemeToDefaults()
        }
    }

    let NS_PER_S = 1_000_000_000.0

    private var llamaContext: LlamaContext?

    private let chatStoreFilename = "chat_store_v2.json"
    private let legacyChatHistoryFilename = "chat_history.json"
    private let lastModelFilenameKey = "last_loaded_model_filename"
    private let themeStorageKey = "chat_theme_v1"
    private let maxPromptCharacters = 4_000
    private let maxMemoryNotesPerThread = 24
    private let maxGlobalMemoryNotes = 80

    private let systemPrompt = "You are a helpful, concise assistant running fully on iPhone. Maintain continuity across turns and use memory facts when relevant."

    private var defaultModelUrl: URL? {
        nil
    }

    var sortedThreads: [ChatThread] {
        threads.sorted { $0.updatedAt > $1.updatedAt }
    }

    var activeThreadMemoryNotes: [String] {
        guard let idx = activeThreadIndex() else { return [] }
        return threads[idx].memoryNotes
    }

    init() {
        messageLog = """
        Qwen iPhone ready.
        Load a GGUF model once, then chat continuously with memory.
        """

        loadThemeFromDefaults()
        loadModelsFromDisk()
        loadDefaultModels()
        loadChatStoreFromDiskOrMigrate()
        ensureAtLeastOneThread()
        syncActiveThreadSnapshot()
        autoLoadLastModelIfPresent()
    }

    func applyThemePreset(_ preset: ThemePreset) {
        theme = .preset(preset)
    }

    func resetTheme() {
        applyThemePreset(.blackGold)
    }

    func themeColor(_ slot: ThemeColorSlot) -> Color {
        switch slot {
        case .accent:
            return theme.accent.color
        case .backgroundTop:
            return theme.backgroundTop.color
        case .backgroundBottom:
            return theme.backgroundBottom.color
        case .panel:
            return theme.panel.color
        case .userBubble:
            return theme.userBubble.color
        case .assistantBubble:
            return theme.assistantBubble.color
        case .userText:
            return theme.userText.color
        case .assistantText:
            return theme.assistantText.color
        }
    }

    func setThemeColor(_ slot: ThemeColorSlot, color: Color) {
        let newColor = ThemeRGBA.from(color)
        mutateTheme { theme in
            theme.preset = nil
            switch slot {
            case .accent:
                theme.accent = newColor
            case .backgroundTop:
                theme.backgroundTop = newColor
            case .backgroundBottom:
                theme.backgroundBottom = newColor
            case .panel:
                theme.panel = newColor
            case .userBubble:
                theme.userBubble = newColor
            case .assistantBubble:
                theme.assistantBubble = newColor
            case .userText:
                theme.userText = newColor
            case .assistantText:
                theme.assistantText = newColor
            }
        }
    }

    func setThemeFontScale(_ value: Double) {
        mutateTheme { theme in
            theme.preset = nil
            theme.fontScale = min(max(value, 0.85), 1.35)
        }
    }

    func setThemeBubbleCornerRadius(_ value: Double) {
        mutateTheme { theme in
            theme.preset = nil
            theme.bubbleCornerRadius = min(max(value, 10), 28)
        }
    }

    func setThemeInputCornerRadius(_ value: Double) {
        mutateTheme { theme in
            theme.preset = nil
            theme.inputCornerRadius = min(max(value, 10), 24)
        }
    }

    private func mutateTheme(_ mutate: (inout ChatTheme) -> Void) {
        var updated = theme
        mutate(&updated)
        theme = updated
    }

    private func persistThemeToDefaults() {
        do {
            let data = try JSONEncoder().encode(theme)
            UserDefaults.standard.set(data, forKey: themeStorageKey)
        } catch {
            messageLog += "Could not save theme: \(error.localizedDescription)\n"
        }
    }

    private func loadThemeFromDefaults() {
        guard let data = UserDefaults.standard.data(forKey: themeStorageKey) else {
            return
        }

        do {
            theme = try JSONDecoder().decode(ChatTheme.self, from: data)
        } catch {
            messageLog += "Could not load saved theme: \(error.localizedDescription)\n"
            theme = .preset(.blackGold)
        }
    }

    func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private func chatStoreURL() -> URL {
        getDocumentsDirectory().appendingPathComponent(chatStoreFilename)
    }

    private func legacyHistoryURL() -> URL {
        getDocumentsDirectory().appendingPathComponent(legacyChatHistoryFilename)
    }

    private func activeThreadIndex() -> Int? {
        guard let activeThreadID else { return nil }
        return threads.firstIndex(where: { $0.id == activeThreadID })
    }

    private func ensureAtLeastOneThread() {
        if threads.isEmpty {
            let starter = ChatMessage(role: .assistant, text: "Load a model in Settings, then start chatting.")
            let thread = ChatThread(messages: [starter])
            threads = [thread]
            activeThreadID = thread.id
            persistChatStoreToDisk()
        }

        if activeThreadID == nil {
            activeThreadID = threads.first?.id
        }

        if activeThreadIndex() == nil {
            activeThreadID = threads.first?.id
        }
    }

    private func syncActiveThreadSnapshot() {
        guard let idx = activeThreadIndex() else {
            activeThreadTitle = "New Chat"
            messages = []
            return
        }

        activeThreadTitle = threads[idx].title
        messages = threads[idx].messages
    }

    private func withActiveThread(
        persist: Bool = true,
        sync: Bool = true,
        _ mutate: (inout ChatThread) -> Void
    ) {
        guard let idx = activeThreadIndex() else { return }
        mutate(&threads[idx])
        threads[idx].updatedAt = Date()
        if sync { syncActiveThreadSnapshot() }
        if persist { persistChatStoreToDisk() }
    }

    private func appendMessageToActiveThread(_ message: ChatMessage, persist: Bool = true) {
        withActiveThread(persist: persist) { thread in
            thread.messages.append(message)
            if thread.title == "New Chat" && message.role == .user {
                thread.title = makeThreadTitle(from: message.text)
            }
        }
    }

    private func makeThreadTitle(from text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "New Chat" }
        if trimmed.count <= 48 { return trimmed }
        let idx = trimmed.index(trimmed.startIndex, offsetBy: 48)
        return String(trimmed[..<idx]) + "…"
    }

    private func updateAssistantMessage(_ assistantID: UUID, append token: String, persist: Bool = false) {
        withActiveThread(persist: persist) { thread in
            guard let messageIndex = thread.messages.firstIndex(where: { $0.id == assistantID }) else { return }
            thread.messages[messageIndex].text += token
        }
    }

    func createThreadAndSwitch() {
        guard !isGenerating else {
            messageLog += "Wait for generation to finish before creating a new chat.\n"
            return
        }

        let starter = ChatMessage(role: .assistant, text: "New chat started. Ask anything.")
        let thread = ChatThread(messages: [starter])
        threads.append(thread)
        activeThreadID = thread.id
        syncActiveThreadSnapshot()
        persistChatStoreToDisk()
    }

    func switchToThread(_ threadID: UUID) {
        guard !isGenerating else {
            messageLog += "Cannot switch chats while generating.\n"
            return
        }
        guard threads.contains(where: { $0.id == threadID }) else { return }
        activeThreadID = threadID
        syncActiveThreadSnapshot()
        persistChatStoreToDisk()
    }

    func deleteThreads(at offsets: IndexSet) {
        guard !isGenerating else {
            messageLog += "Cannot delete chats while generating.\n"
            return
        }

        let sorted = sortedThreads
        let idsToDelete = offsets.map { sorted[$0].id }
        threads.removeAll { idsToDelete.contains($0.id) }

        if let activeThreadID, idsToDelete.contains(activeThreadID) {
            self.activeThreadID = threads.sorted { $0.updatedAt > $1.updatedAt }.first?.id
        }

        ensureAtLeastOneThread()
        syncActiveThreadSnapshot()
        persistChatStoreToDisk()
    }

    func clearActiveThreadMemory() {
        withActiveThread { thread in
            thread.memoryNotes = []
        }
    }

    func addGlobalMemoryNote(_ rawNote: String, persist: Bool = true) {
        let note = normalizeMemoryNote(rawNote)
        guard !note.isEmpty else { return }
        if !globalMemoryNotes.contains(note) {
            globalMemoryNotes.append(note)
            if globalMemoryNotes.count > maxGlobalMemoryNotes {
                globalMemoryNotes.removeFirst(globalMemoryNotes.count - maxGlobalMemoryNotes)
            }
            if persist {
                persistChatStoreToDisk()
            }
        }
    }

    func deleteGlobalMemoryNotes(at offsets: IndexSet) {
        globalMemoryNotes.remove(atOffsets: offsets)
        persistChatStoreToDisk()
    }

    private func addThreadMemoryNote(_ rawNote: String, persist: Bool = true) {
        let note = normalizeMemoryNote(rawNote)
        guard !note.isEmpty else { return }

        withActiveThread(persist: persist) { thread in
            if !thread.memoryNotes.contains(note) {
                thread.memoryNotes.append(note)
                if thread.memoryNotes.count > maxMemoryNotesPerThread {
                    thread.memoryNotes.removeFirst(thread.memoryNotes.count - maxMemoryNotesPerThread)
                }
            }
        }
    }

    private func normalizeMemoryNote(_ text: String) -> String {
        let oneLine = text
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !oneLine.isEmpty else { return "" }

        if oneLine.count <= 160 {
            return oneLine
        }
        let idx = oneLine.index(oneLine.startIndex, offsetBy: 160)
        return String(oneLine[..<idx]) + "…"
    }

    private func maybeCaptureAutoMemory(from userText: String) {
        let trimmed = userText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard !trimmed.hasPrefix("/") else { return }
        let lower = trimmed.lowercased()
        let notes = extractAutoMemoryNotes(from: trimmed, lowercased: lower)
        guard !notes.isEmpty else { return }

        for note in notes {
            addGlobalMemoryNote(note, persist: false)
            addThreadMemoryNote(note, persist: false)
        }
        persistChatStoreToDisk()
    }

    private func extractAutoMemoryNotes(from text: String, lowercased: String) -> [String] {
        var notes: [String] = []

        func appendNote(_ value: String) {
            let note = normalizeMemoryNote(value)
            guard !note.isEmpty else { return }
            if !notes.contains(note) {
                notes.append(note)
            }
        }

        if lowercased.hasPrefix("my name is ") {
            let name = text.dropFirst("my name is ".count)
            appendNote("User name: \(name)")
        }

        if lowercased.hasPrefix("call me ") {
            let preferredName = text.dropFirst("call me ".count)
            appendNote("User preferred name: \(preferredName)")
        }

        if lowercased.hasPrefix("i live in ") {
            let location = text.dropFirst("i live in ".count)
            appendNote("User location: \(location)")
        } else if lowercased.hasPrefix("i am from ") {
            let origin = text.dropFirst("i am from ".count)
            appendNote("User location: \(origin)")
        } else if lowercased.hasPrefix("i'm from ") {
            let origin = text.dropFirst("i'm from ".count)
            appendNote("User location: \(origin)")
        }

        if lowercased.hasPrefix("my timezone is ") {
            let timezone = text.dropFirst("my timezone is ".count)
            appendNote("User timezone: \(timezone)")
        }

        if lowercased.hasPrefix("i prefer ") {
            appendNote("Preference: \(text)")
        } else if lowercased.hasPrefix("i like ") {
            appendNote("Likes: \(text)")
        } else if lowercased.hasPrefix("i don't like ") || lowercased.hasPrefix("i dont like ") || lowercased.hasPrefix("i dislike ") {
            appendNote("Dislikes: \(text)")
        }

        if lowercased.hasPrefix("my favorite "), let range = text.range(of: " is ", options: .caseInsensitive) {
            let left = String(text[..<range.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            let right = String(text[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
            if !left.isEmpty && !right.isEmpty {
                appendNote("\(left.capitalized): \(right)")
            }
        }

        if lowercased.hasPrefix("i work as ") {
            let job = text.dropFirst("i work as ".count)
            appendNote("User occupation: \(job)")
        } else if lowercased.hasPrefix("i am a ") {
            let role = text.dropFirst("i am a ".count)
            appendNote("User role: \(role)")
        } else if lowercased.hasPrefix("i am an ") {
            let role = text.dropFirst("i am an ".count)
            appendNote("User role: \(role)")
        }

        if lowercased.hasPrefix("my birthday is ") {
            let birthday = text.dropFirst("my birthday is ".count)
            appendNote("User birthday: \(birthday)")
        }

        if lowercased.hasPrefix("i use ") {
            let tools = text.dropFirst("i use ".count)
            appendNote("User uses: \(tools)")
        }

        return notes
    }

    private func memoryCommandResponse(for userText: String) -> String? {
        let trimmed = userText.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = trimmed.lowercased()

        if lower.hasPrefix("/remember ") {
            let note = String(trimmed.dropFirst("/remember ".count))
            addGlobalMemoryNote(note)
            addThreadMemoryNote(note)
            return "Saved memory note."
        }

        if lower == "/memory" {
            var lines: [String] = []
            if globalMemoryNotes.isEmpty && activeThreadMemoryNotes.isEmpty {
                return "No memory notes saved yet. Use /remember <fact>."
            }

            if !globalMemoryNotes.isEmpty {
                lines.append("Global memory:")
                for note in globalMemoryNotes {
                    lines.append("- \(note)")
                }
            }

            if !activeThreadMemoryNotes.isEmpty {
                lines.append("Thread memory:")
                for note in activeThreadMemoryNotes {
                    lines.append("- \(note)")
                }
            }

            return lines.joined(separator: "\n")
        }

        return nil
    }

    private func buildMemoryContext(for thread: ChatThread) -> String {
        var sections: [String] = []

        if !globalMemoryNotes.isEmpty {
            let lines = globalMemoryNotes.prefix(20).map { "- \($0)" }.joined(separator: "\n")
            sections.append("Global memory:\n\(lines)")
        }

        if !thread.memoryNotes.isEmpty {
            let lines = thread.memoryNotes.prefix(20).map { "- \($0)" }.joined(separator: "\n")
            sections.append("Thread memory:\n\(lines)")
        }

        return sections.joined(separator: "\n\n")
    }

    private func buildPromptMessages(for thread: ChatThread) -> [(role: String, content: String)] {
        var selected: [ChatMessage] = []
        var charBudget = 0

        let eligible = thread.messages.filter {
            !($0.role == .assistant && $0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }

        for message in eligible.reversed() {
            let cost = message.text.utf8.count + 32
            if charBudget + cost > maxPromptCharacters && !selected.isEmpty {
                break
            }
            charBudget += cost
            selected.append(message)
        }

        selected.reverse()

        var system = systemPrompt
        let memoryContext = buildMemoryContext(for: thread)
        if !memoryContext.isEmpty {
            system += "\n\nUse these memory notes when relevant:\n\(memoryContext)"
        }

        var result: [(role: String, content: String)] = [("system", system)]
        for message in selected {
            let role = message.role == .user ? "user" : "assistant"
            var content = message.text
            if useNoThinkByDefault,
               message.role == .user,
               !content.hasPrefix("/think"),
               !content.hasPrefix("/no_think") {
                content = "/no_think\n" + content
            }
            result.append((role, content))
        }

        return result
    }

    private func buildRetryPromptMessages(for thread: ChatThread, latestUserText: String) -> [(role: String, content: String)] {
        var system = systemPrompt
        let memoryContext = buildMemoryContext(for: thread)
        if !memoryContext.isEmpty {
            system += "\n\nUse these memory notes when relevant:\n\(memoryContext)"
        }

        var userContent = latestUserText
        if useNoThinkByDefault,
           !userContent.hasPrefix("/think"),
           !userContent.hasPrefix("/no_think") {
            userContent = "/no_think\n" + userContent
        }

        return [
            ("system", system),
            ("user", userContent)
        ]
    }

    private func buildEmergencyPromptMessages(latestUserText: String) -> [(role: String, content: String)] {
        [
            (
                "system",
                """
                You are a helpful on-device assistant.
                Always output a direct answer in plain text.
                Do not output only control tags or hidden thinking blocks.
                """
            ),
            ("user", latestUserText)
        ]
    }

    func sendDraft() {
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        guard let llamaContext else {
            messageLog += "Load a model before sending messages.\n"
            return
        }

        guard !isLoadingModel else {
            messageLog += "Wait for model loading to finish.\n"
            return
        }

        guard !isGenerating else {
            return
        }

        appendMessageToActiveThread(ChatMessage(role: .user, text: trimmed))
        maybeCaptureAutoMemory(from: trimmed)
        draft = ""

        if let commandReply = memoryCommandResponse(for: trimmed) {
            appendMessageToActiveThread(ChatMessage(role: .assistant, text: commandReply))
            return
        }

        guard let idx = activeThreadIndex() else { return }
        let promptMessages = buildPromptMessages(for: threads[idx])

        let assistantMessageID = UUID()
        appendMessageToActiveThread(ChatMessage(id: assistantMessageID, role: .assistant, text: ""), persist: false)

        isGenerating = true
        let tStart = DispatchTime.now().uptimeNanoseconds

        Task {
            await llamaContext.completion_init(messages: promptMessages)

            while await !llamaContext.is_done {
                let token = await llamaContext.completion_loop()
                if !token.isEmpty {
                    updateAssistantMessage(assistantMessageID, append: token)
                }
            }

            var generatedTokens = await llamaContext.get_n_decode()
            await llamaContext.clear()

            var needsRetry = false
            if let retryIndex = activeThreadIndex(),
               let messageIndex = threads[retryIndex].messages.firstIndex(where: { $0.id == assistantMessageID }),
               threads[retryIndex].messages[messageIndex].text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                needsRetry = true
            }

            if needsRetry, let retryIndex = activeThreadIndex() {
                messageLog += "First pass returned empty output. Retrying with compact context...\n"
                let retryMessages = buildRetryPromptMessages(for: threads[retryIndex], latestUserText: trimmed)
                await llamaContext.completion_init(messages: retryMessages)

                while await !llamaContext.is_done {
                    let token = await llamaContext.completion_loop()
                    if !token.isEmpty {
                        updateAssistantMessage(assistantMessageID, append: token, persist: false)
                    }
                }

                generatedTokens += await llamaContext.get_n_decode()
                await llamaContext.clear()
            }

            var needsEmergencyRetry = false
            if let retryIndex = activeThreadIndex(),
               let messageIndex = threads[retryIndex].messages.firstIndex(where: { $0.id == assistantMessageID }),
               threads[retryIndex].messages[messageIndex].text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                needsEmergencyRetry = true
            }

            if needsEmergencyRetry {
                messageLog += "Second pass empty. Retrying with emergency prompt...\n"
                let emergencyMessages = buildEmergencyPromptMessages(latestUserText: trimmed)
                await llamaContext.completion_init(messages: emergencyMessages)

                while await !llamaContext.is_done {
                    let token = await llamaContext.completion_loop()
                    if !token.isEmpty {
                        updateAssistantMessage(assistantMessageID, append: token, persist: false)
                    }
                }

                generatedTokens += await llamaContext.get_n_decode()
                await llamaContext.clear()
            }

            var needsDeterministicRetry = false
            if let retryIndex = activeThreadIndex(),
               let messageIndex = threads[retryIndex].messages.firstIndex(where: { $0.id == assistantMessageID }),
               threads[retryIndex].messages[messageIndex].text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                needsDeterministicRetry = true
            }

            if needsDeterministicRetry {
                messageLog += "Emergency pass empty. Retrying with deterministic sampler...\n"
                let deterministicMessages = buildEmergencyPromptMessages(
                    latestUserText: trimmed + "\n\nRespond with at least one complete sentence."
                )
                await llamaContext.completion_init(messages: deterministicMessages, deterministic: true)

                while await !llamaContext.is_done {
                    let token = await llamaContext.completion_loop()
                    if !token.isEmpty {
                        updateAssistantMessage(assistantMessageID, append: token, persist: false)
                    }
                }

                generatedTokens += await llamaContext.get_n_decode()
                await llamaContext.clear()
            }

            let tEnd = DispatchTime.now().uptimeNanoseconds

            let elapsed = Double(tEnd - tStart) / NS_PER_S
            let tps = elapsed > 0 ? Double(generatedTokens) / elapsed : 0

            withActiveThread { thread in
                if let messageIndex = thread.messages.firstIndex(where: { $0.id == assistantMessageID }) {
                    if thread.messages[messageIndex].text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        thread.messages[messageIndex].text = "I couldn't generate a reply on this turn. Tap Send once to retry."
                    }
                }
            }

            isGenerating = false
            messageLog += String(format: "Reply done: %d tokens in %.2fs (%.2f t/s).\n", generatedTokens, elapsed, tps)
            persistChatStoreToDisk()
        }
    }

    func newConversation() {
        createThreadAndSwitch()
    }

    func clearConversation() {
        guard !isGenerating else { return }
        withActiveThread { thread in
            thread.messages = [ChatMessage(role: .assistant, text: "Conversation cleared. Start a new message.")]
            thread.memoryNotes = []
            thread.title = "New Chat"
        }
    }

    func copyConversationToPasteboardText() -> String {
        var lines: [String] = []
        for message in messages {
            let prefix = message.role == .user ? "User" : "Assistant"
            lines.append("\(prefix): \(message.text)")
        }
        return lines.joined(separator: "\n\n")
    }

    func runBench() async {
        guard let llamaContext else {
            messageLog += "Load a model before running bench.\n"
            return
        }

        messageLog += "Running benchmark...\n"
        messageLog += "Model info: \(await llamaContext.model_info())\n"

        let tStart = DispatchTime.now().uptimeNanoseconds
        _ = await llamaContext.bench(pp: 8, tg: 4, pl: 1)
        let tEnd = DispatchTime.now().uptimeNanoseconds

        let warmup = Double(tEnd - tStart) / NS_PER_S
        messageLog += String(format: "Warmup: %.2fs\n", warmup)

        let result = await llamaContext.bench(pp: 512, tg: 128, pl: 1, nr: 3)
        messageLog += result + "\n"
    }

    private func persistChatStoreToDisk() {
        let store = ChatStore(
            threads: threads,
            activeThreadID: activeThreadID,
            globalMemoryNotes: globalMemoryNotes
        )

        do {
            let data = try JSONEncoder().encode(store)
            try data.write(to: chatStoreURL(), options: .atomic)
        } catch {
            messageLog += "Could not save chat store: \(error.localizedDescription)\n"
        }
    }

    private func loadChatStoreFromDiskOrMigrate() {
        let storeURL = chatStoreURL()
        if FileManager.default.fileExists(atPath: storeURL.path) {
            do {
                let data = try Data(contentsOf: storeURL)
                let restored = try JSONDecoder().decode(ChatStore.self, from: data)
                threads = restored.threads
                activeThreadID = restored.activeThreadID
                globalMemoryNotes = restored.globalMemoryNotes
                return
            } catch {
                messageLog += "Could not load chat store: \(error.localizedDescription)\n"
            }
        }

        migrateLegacyConversationIfPresent()
    }

    private func migrateLegacyConversationIfPresent() {
        let url = legacyHistoryURL()
        guard FileManager.default.fileExists(atPath: url.path) else {
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let restoredMessages = try JSONDecoder().decode([ChatMessage].self, from: data)
            let migrated = ChatThread(title: "Migrated Chat", messages: restoredMessages)
            threads = [migrated]
            activeThreadID = migrated.id
            persistChatStoreToDisk()
        } catch {
            messageLog += "Could not migrate legacy chat history: \(error.localizedDescription)\n"
        }
    }

    // Backward-compatible wrappers
    func complete(text: String) async {
        draft = text
        sendDraft()
    }

    func bench() async {
        await runBench()
    }

    func clear() async {
        clearConversation()
    }

    // Model management
    private func loadModelsFromDisk() {
        do {
            let documentsURL = getDocumentsDirectory()
            let modelURLs = try FileManager.default.contentsOfDirectory(
                at: documentsURL,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants]
            )
            for modelURL in modelURLs where modelURL.pathExtension.lowercased() == "gguf" {
                let modelName = modelURL.deletingPathExtension().lastPathComponent
                registerDownloadedModelIfNeeded(
                    Model(name: modelName, url: "", filename: modelURL.lastPathComponent, status: "downloaded")
                )
            }
        } catch {
            messageLog += "Error loading models from disk: \(error.localizedDescription)\n"
        }
    }

    private func loadDefaultModels() {
        if let defaultModelUrl {
            loadModel(modelUrl: defaultModelUrl)
        }

        for model in defaultModels {
            let fileURL = getDocumentsDirectory().appendingPathComponent(model.filename)
            if !FileManager.default.fileExists(atPath: fileURL.path) {
                undownloadedModels.append(model)
            }
        }
    }

    private let defaultModels: [Model] = [
        Model(
            name: "Qwen3-1.7B (Q4_0, 1.11 GiB)",
            url: "https://huggingface.co/ggml-org/Qwen3-1.7B-GGUF/resolve/main/Qwen3-1.7B-Q4_0.gguf?download=true",
            filename: "Qwen3-1.7B-Q4_0.gguf",
            status: "download"
        ),
        Model(
            name: "Qwen3-1.7B (Q4_K_M, 1.28 GiB)",
            url: "https://huggingface.co/ggml-org/Qwen3-1.7B-GGUF/resolve/main/Qwen3-1.7B-Q4_K_M.gguf?download=true",
            filename: "Qwen3-1.7B-Q4_K_M.gguf",
            status: "download"
        ),
        Model(
            name: "Qwen3-4B (Q4_0, 2.37 GiB)",
            url: "https://huggingface.co/ggml-org/Qwen3-4B-GGUF/resolve/main/Qwen3-4B-Q4_0.gguf?download=true",
            filename: "Qwen3-4B-Q4_0.gguf",
            status: "download"
        ),
        Model(
            name: "Qwen3-4B (Q4_K_M, 2.72 GiB)",
            url: "https://huggingface.co/ggml-org/Qwen3-4B-GGUF/resolve/main/Qwen3-4B-Q4_K_M.gguf?download=true",
            filename: "Qwen3-4B-Q4_K_M.gguf",
            status: "download"
        )
    ]

    func registerDownloadedModelIfNeeded(_ model: Model) {
        if !downloadedModels.contains(where: { $0.filename == model.filename }) {
            downloadedModels.append(model)
        }
        undownloadedModels.removeAll { $0.filename == model.filename }
    }

    func deleteDownloadedModels(at offsets: IndexSet) {
        for offset in offsets {
            let model = downloadedModels[offset]
            let fileURL = getDocumentsDirectory().appendingPathComponent(model.filename)
            do {
                if FileManager.default.fileExists(atPath: fileURL.path) {
                    try FileManager.default.removeItem(at: fileURL)
                }
            } catch {
                messageLog += "Failed deleting \(model.filename): \(error.localizedDescription)\n"
            }

            if model.filename == currentModelName {
                unloadModel()
            }
        }
        downloadedModels.remove(atOffsets: offsets)
    }

    func unloadModel() {
        if isGenerating {
            messageLog += "Cannot unload while generation is in progress.\n"
            return
        }
        llamaContext = nil
        isModelLoaded = false
        currentModelName = "No model loaded"
        UserDefaults.standard.removeObject(forKey: lastModelFilenameKey)
        messageLog += "Model unloaded.\n"
    }

    private func autoLoadLastModelIfPresent() {
        guard !isModelLoaded else { return }
        guard let filename = UserDefaults.standard.string(forKey: lastModelFilenameKey) else { return }

        let fileURL = getDocumentsDirectory().appendingPathComponent(filename)
        if FileManager.default.fileExists(atPath: fileURL.path) {
            loadModel(modelUrl: fileURL)
        } else {
            UserDefaults.standard.removeObject(forKey: lastModelFilenameKey)
        }
    }

    func loadModel(modelUrl: URL?) {
        guard let modelUrl else {
            messageLog += "Load a model from the list below.\n"
            return
        }

        guard !isLoadingModel else {
            messageLog += "A model is already loading. Please wait.\n"
            return
        }

        guard validateModelFile(modelUrl) else {
            return
        }

        let modelPath = modelUrl.path()
        let modelName = modelUrl.lastPathComponent
        isLoadingModel = true
        loadingModelName = modelName
        messageLog += "Loading model \(modelName)...\n"

        Task.detached(priority: .userInitiated) {
            do {
                let context = try LlamaContext.create_context(path: modelPath)
                await MainActor.run {
                    guard self.loadingModelName == modelName else { return }
                    self.llamaContext = context
                    self.isLoadingModel = false
                    self.loadingModelName = ""
                    self.isModelLoaded = true
                    self.currentModelName = modelName
                    UserDefaults.standard.set(modelName, forKey: self.lastModelFilenameKey)
                    self.registerDownloadedModelIfNeeded(
                        Model(name: modelName, url: "", filename: modelName, status: "downloaded")
                    )
                    self.messageLog += "Loaded model \(modelName).\n"
                }
            } catch {
                await MainActor.run {
                    guard self.loadingModelName == modelName else { return }
                    self.isLoadingModel = false
                    self.loadingModelName = ""
                    self.isModelLoaded = false
                    self.currentModelName = "No model loaded"
                    self.messageLog += "Model load failed: \(error.localizedDescription)\n"
                    self.messageLog += "If this is a Qwen3 model, confirm your llama.xcframework is recent.\n"
                }
            }
        }
    }

    private func validateModelFile(_ modelUrl: URL) -> Bool {
        let path = modelUrl.path
        guard FileManager.default.fileExists(atPath: path) else {
            messageLog += "Model file not found: \(modelUrl.lastPathComponent)\n"
            return false
        }

        if modelUrl.pathExtension.lowercased() != "gguf" {
            messageLog += "Selected file is not a .gguf model: \(modelUrl.lastPathComponent)\n"
            return false
        }

        do {
            let values = try modelUrl.resourceValues(forKeys: [.fileSizeKey])
            if let size = values.fileSize, size < 128 * 1024 * 1024 {
                messageLog += "Model file is too small (\(size) bytes). Re-download and try again.\n"
                return false
            }
        } catch {
            messageLog += "Could not inspect model size: \(error.localizedDescription)\n"
        }

        return true
    }
}
