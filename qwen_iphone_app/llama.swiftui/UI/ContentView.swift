import SwiftUI

struct ContentView: View {
    @StateObject private var llamaState = LlamaState()
    @State private var showModelDrawer = false
    @State private var showThreadDrawer = false
    @FocusState private var composerFocused: Bool

    private var theme: ChatTheme {
        llamaState.theme
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [theme.backgroundTop.color, theme.backgroundBottom.color],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                header
                chatStream
                composer
            }
        }
        .sheet(isPresented: $showModelDrawer) {
            ModelDrawerView(llamaState: llamaState)
        }
        .sheet(isPresented: $showThreadDrawer) {
            ThreadDrawerView(llamaState: llamaState)
        }
        .tint(theme.accent.color)
    }

    private var header: some View {
        HStack(spacing: 12) {
            Button {
                showThreadDrawer = true
            } label: {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(theme.accent.color)
                    .frame(width: 36, height: 36)
                    .background(theme.panel.color.opacity(0.82), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(llamaState.activeThreadTitle)
                    .font(.headline)
                    .foregroundStyle(theme.accent.color)
                    .lineLimit(1)

                Text(llamaState.currentModelName)
                    .font(.caption)
                    .foregroundStyle(theme.assistantText.color.opacity(0.75))
                    .lineLimit(1)
            }

            Spacer()

            Button {
                llamaState.createThreadAndSwitch()
            } label: {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(theme.accent.color)
                    .frame(width: 36, height: 36)
                    .background(theme.panel.color.opacity(0.82), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .disabled(llamaState.isGenerating)

            Button {
                showModelDrawer = true
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(theme.accent.color)
                    .frame(width: 36, height: 36)
                    .background(theme.panel.color.opacity(0.82), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 14)
        .padding(.bottom, 10)
        .background(theme.panel.color.opacity(0.58))
    }

    private var chatStream: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(llamaState.messages) { message in
                        ChatBubble(message: message, theme: theme)
                            .id(message.id)
                    }

                    if llamaState.isGenerating {
                        HStack {
                            Text("Thinking...")
                                .foregroundStyle(theme.accent.color)
                                .font(.footnote)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(theme.assistantBubble.color.opacity(0.9), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(theme.accent.color.opacity(0.4), lineWidth: 1)
                                )
                            Spacer()
                        }
                        .padding(.horizontal, 10)
                    }

                    Color.clear
                        .frame(height: 1)
                        .id("chat-bottom")
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 14)
            }
            .onChange(of: llamaState.messages.count) { _ in
                withAnimation(.easeOut(duration: 0.18)) {
                    proxy.scrollTo("chat-bottom", anchor: .bottom)
                }
            }
            .onChange(of: llamaState.messages.last?.text ?? "") { _ in
                withAnimation(.linear(duration: 0.1)) {
                    proxy.scrollTo("chat-bottom", anchor: .bottom)
                }
            }
        }
    }

    private var composer: some View {
        VStack(spacing: 8) {
            if llamaState.isLoadingModel {
                HStack(spacing: 8) {
                    ProgressView()
                        .tint(theme.accent.color)
                    Text("Loading \(llamaState.loadingModelName)...")
                        .font(.caption)
                        .foregroundStyle(theme.accent.color)
                    Spacer()
                }
            }

            HStack(alignment: .bottom, spacing: 10) {
                TextEditor(text: $llamaState.draft)
                    .font(.system(size: 16 * theme.fontScale))
                    .foregroundStyle(theme.assistantText.color)
                    .focused($composerFocused)
                    .frame(minHeight: 42, maxHeight: 120)
                    .padding(8)
                    .background(theme.panel.color.opacity(0.92), in: RoundedRectangle(cornerRadius: theme.inputCornerRadius, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: theme.inputCornerRadius, style: .continuous)
                            .stroke(theme.accent.color.opacity(0.45), lineWidth: 1)
                    )

                Button {
                    composerFocused = false
                    llamaState.sendDraft()
                } label: {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(theme.userText.color)
                        .frame(width: 42, height: 42)
                        .background(theme.accent.color, in: Circle())
                }
                .disabled(!canSend)
                .opacity(canSend ? 1.0 : 0.35)
            }

            HStack {
                Text(statusLine)
                    .font(.caption2)
                    .foregroundStyle(theme.assistantText.color.opacity(0.7))
                Spacer()
                Button("Copy") {
                    UIPasteboard.general.string = llamaState.copyConversationToPasteboardText()
                }
                .font(.caption2)
                .foregroundStyle(theme.accent.color)
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 10)
        .padding(.bottom, 12)
        .background(theme.panel.color.opacity(0.72))
    }

    private var canSend: Bool {
        let textReady = !llamaState.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return textReady && llamaState.isModelLoaded && !llamaState.isGenerating && !llamaState.isLoadingModel
    }

    private var statusLine: String {
        if !llamaState.isModelLoaded {
            return "Open settings and load a model to start."
        }
        if llamaState.isGenerating {
            return "Generating reply..."
        }
        return "Auto-memory is active. Use /memory to inspect saved notes."
    }
}

private struct ChatBubble: View {
    let message: ChatMessage
    let theme: ChatTheme
    @State private var showThinking = false

    private var isUser: Bool {
        message.role == .user
    }

    private var assistantParts: AssistantMessageParts {
        AssistantMessageParts.parse(message.text)
    }

    var body: some View {
        HStack {
            if isUser {
                Spacer(minLength: 42)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(isUser ? "You" : "Assistant")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(isUser ? theme.userText.color.opacity(0.7) : theme.accent.color.opacity(0.95))

                if isUser {
                    MarkdownMessageText(
                        text: message.text,
                        foreground: theme.userText.color,
                        tint: theme.userText.color,
                        fontSize: 16 * theme.fontScale
                    )
                } else {
                    if !assistantParts.visibleText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        MarkdownMessageText(
                            text: assistantParts.visibleText,
                            foreground: theme.assistantText.color,
                            tint: theme.accent.color,
                            fontSize: 16 * theme.fontScale
                        )
                    } else if assistantParts.hasThinking {
                        Text("Reasoning captured. Expand to view.")
                            .font(.body)
                            .foregroundStyle(theme.assistantText.color.opacity(0.88))
                    }

                    if assistantParts.hasThinking {
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showThinking.toggle()
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: showThinking ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                                    .font(.caption)
                                Text(showThinking ? "Hide reasoning" : "Show reasoning")
                                    .font(.caption.weight(.semibold))
                                if assistantParts.hasUnclosedThinkTag {
                                    Text("(streaming)")
                                        .font(.caption2)
                                }
                            }
                            .foregroundStyle(theme.accent.color.opacity(0.95))
                            .padding(.top, 2)
                        }
                        .buttonStyle(.plain)

                        if showThinking {
                            MarkdownMessageText(
                                text: assistantParts.thinkingText,
                                foreground: theme.assistantText.color.opacity(0.78),
                                tint: theme.accent.color.opacity(0.85),
                                fontSize: 13 * theme.fontScale
                            )
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(theme.panel.color.opacity(0.55), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                    }
                }
            }
            .padding(.horizontal, 13)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: theme.bubbleCornerRadius, style: .continuous)
                    .fill(isUser ? theme.userBubble.color : theme.assistantBubble.color.opacity(0.96))
            )
            .overlay(
                RoundedRectangle(cornerRadius: theme.bubbleCornerRadius, style: .continuous)
                    .stroke(theme.accent.color.opacity(isUser ? 0.0 : 0.42), lineWidth: 1)
            )

            if !isUser {
                Spacer(minLength: 42)
            }
        }
        .transition(.opacity.combined(with: .move(edge: isUser ? .trailing : .leading)))
    }
}

private struct MarkdownMessageText: View {
    let text: String
    let foreground: Color
    let tint: Color
    var fontSize: Double = 16

    var body: some View {
        let blocks = MarkdownBlockParser.parse(text)
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                blockView(block)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func blockView(_ block: MarkdownBlock) -> some View {
        switch block {
        case .spacer:
            Color.clear
                .frame(height: 2)
        case .paragraph(let value):
            inlineMarkdown(value, font: .system(size: fontSize))
        case .heading(let level, let value):
            let size = fontSize + max(1, Double(7 - level)) * 1.1
            inlineMarkdown(value, font: .system(size: size, weight: .semibold))
        case .bullet(let value):
            HStack(alignment: .top, spacing: 8) {
                Text("•")
                    .font(.system(size: fontSize, weight: .bold))
                    .foregroundStyle(tint)
                inlineMarkdown(value, font: .system(size: fontSize))
            }
        case .numbered(let marker, let value):
            HStack(alignment: .top, spacing: 8) {
                Text(marker)
                    .font(.system(size: fontSize, weight: .bold))
                    .foregroundStyle(tint)
                    .frame(minWidth: 28, alignment: .leading)
                inlineMarkdown(value, font: .system(size: fontSize))
            }
        case .quote(let value):
            HStack(alignment: .top, spacing: 8) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(tint.opacity(0.75))
                    .frame(width: 3)
                inlineMarkdown(value, font: .system(size: fontSize))
            }
            .padding(.leading, 2)
        case .code(let language, let value):
            VStack(alignment: .leading, spacing: 6) {
                if let language, !language.isEmpty {
                    Text(language.uppercased())
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(tint.opacity(0.9))
                }
                ScrollView(.horizontal, showsIndicators: false) {
                    Text(value.isEmpty ? " " : value)
                        .font(.system(size: fontSize * 0.9, design: .monospaced))
                        .foregroundStyle(foreground)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(10)
            .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }

    @ViewBuilder
    private func inlineMarkdown(_ raw: String, font: Font) -> some View {
        if let attributed = try? AttributedString(
            markdown: raw,
            options: AttributedString.MarkdownParsingOptions(
                interpretedSyntax: .inlineOnlyPreservingWhitespace,
                failurePolicy: .returnPartiallyParsedIfPossible
            )
        ) {
            Text(attributed)
                .font(font)
                .foregroundStyle(foreground)
                .tint(tint)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            Text(raw)
                .font(font)
                .foregroundStyle(foreground)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private enum MarkdownBlock {
    case paragraph(String)
    case heading(level: Int, text: String)
    case bullet(String)
    case numbered(marker: String, text: String)
    case quote(String)
    case code(language: String?, text: String)
    case spacer
}

private enum MarkdownBlockParser {
    static func parse(_ raw: String) -> [MarkdownBlock] {
        let normalized = raw.replacingOccurrences(of: "\r\n", with: "\n")
        let lines = normalized.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        var blocks: [MarkdownBlock] = []
        var paragraphBuffer: [String] = []
        var index = 0

        func flushParagraph() {
            guard !paragraphBuffer.isEmpty else { return }
            let paragraph = paragraphBuffer.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            paragraphBuffer.removeAll()
            if !paragraph.isEmpty {
                blocks.append(.paragraph(paragraph))
            }
        }

        func appendSpacerIfNeeded() {
            guard let last = blocks.last else { return }
            switch last {
            case .spacer:
                return
            default:
                blocks.append(.spacer)
            }
        }

        while index < lines.count {
            let line = lines[index]
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.isEmpty {
                flushParagraph()
                appendSpacerIfNeeded()
                index += 1
                continue
            }

            if trimmed.hasPrefix("```") {
                flushParagraph()
                let languageRaw = String(trimmed.dropFirst(3)).trimmingCharacters(in: .whitespacesAndNewlines)
                let language = languageRaw.isEmpty ? nil : languageRaw
                var codeLines: [String] = []
                var cursor = index + 1

                while cursor < lines.count {
                    let candidate = lines[cursor].trimmingCharacters(in: .whitespaces)
                    if candidate.hasPrefix("```") {
                        cursor += 1
                        break
                    }
                    codeLines.append(lines[cursor])
                    cursor += 1
                }

                blocks.append(.code(language: language, text: codeLines.joined(separator: "\n")))
                index = cursor
                continue
            }

            if let heading = parseHeading(trimmed) {
                flushParagraph()
                blocks.append(.heading(level: heading.level, text: heading.text))
                index += 1
                continue
            }

            if let bullet = parseBullet(trimmed) {
                flushParagraph()
                blocks.append(.bullet(bullet))
                index += 1
                continue
            }

            if let ordered = parseOrdered(trimmed) {
                flushParagraph()
                blocks.append(.numbered(marker: ordered.marker, text: ordered.text))
                index += 1
                continue
            }

            if let quote = parseQuote(trimmed) {
                flushParagraph()
                var quoteLines: [String] = [quote]
                var cursor = index + 1

                while cursor < lines.count {
                    let nextTrimmed = lines[cursor].trimmingCharacters(in: .whitespaces)
                    guard let nextQuote = parseQuote(nextTrimmed) else { break }
                    quoteLines.append(nextQuote)
                    cursor += 1
                }

                blocks.append(.quote(quoteLines.joined(separator: "\n")))
                index = cursor
                continue
            }

            paragraphBuffer.append(line)
            index += 1
        }

        flushParagraph()

        while let first = blocks.first, case .spacer = first {
            blocks.removeFirst()
        }
        while let last = blocks.last, case .spacer = last {
            blocks.removeLast()
        }

        if blocks.isEmpty {
            return [.paragraph(raw)]
        }

        return blocks
    }

    private static func parseHeading(_ line: String) -> (level: Int, text: String)? {
        var count = 0
        for ch in line {
            if ch == "#" {
                count += 1
            } else {
                break
            }
        }

        guard (1...6).contains(count) else { return nil }
        let split = line.index(line.startIndex, offsetBy: count)
        guard split < line.endIndex, line[split] == " " else { return nil }
        let contentStart = line.index(after: split)
        let text = String(line[contentStart...]).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return nil }
        return (count, text)
    }

    private static func parseBullet(_ line: String) -> String? {
        if line.hasPrefix("- [ ] ") {
            return "☐ " + String(line.dropFirst(6)).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if line.lowercased().hasPrefix("- [x] ") {
            return "☑ " + String(line.dropFirst(6)).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        for prefix in ["- ", "* ", "+ "] {
            if line.hasPrefix(prefix) {
                let text = String(line.dropFirst(prefix.count)).trimmingCharacters(in: .whitespacesAndNewlines)
                return text.isEmpty ? nil : text
            }
        }
        return nil
    }

    private static func parseOrdered(_ line: String) -> (marker: String, text: String)? {
        var cursor = line.startIndex
        while cursor < line.endIndex && line[cursor].isNumber {
            cursor = line.index(after: cursor)
        }

        guard cursor > line.startIndex, cursor < line.endIndex else { return nil }
        let separator = line[cursor]
        guard separator == "." || separator == ")" else { return nil }
        let spaceIndex = line.index(after: cursor)
        guard spaceIndex < line.endIndex, line[spaceIndex] == " " else { return nil }
        let contentStart = line.index(after: spaceIndex)
        let content = String(line[contentStart...]).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else { return nil }

        let marker = String(line[..<spaceIndex])
        return (marker, content)
    }

    private static func parseQuote(_ line: String) -> String? {
        guard line.hasPrefix(">") else { return nil }
        var content = String(line.dropFirst())
        if content.hasPrefix(" ") {
            content.removeFirst()
        }
        return content
    }
}

private struct AssistantMessageParts {
    let visibleText: String
    let thinkingText: String
    let hasUnclosedThinkTag: Bool

    var hasThinking: Bool {
        hasUnclosedThinkTag || !thinkingText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    static func parse(_ rawText: String) -> AssistantMessageParts {
        var remaining = rawText[...]
        var visible = ""
        var thinkBlocks: [String] = []
        var hasUnclosedTag = false

        while let openRange = remaining.range(of: "<think>") {
            visible += String(remaining[..<openRange.lowerBound])
            let afterOpen = remaining[openRange.upperBound...]

            if let closeRange = afterOpen.range(of: "</think>") {
                let thinkBody = String(afterOpen[..<closeRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                if !thinkBody.isEmpty {
                    thinkBlocks.append(thinkBody)
                }
                remaining = afterOpen[closeRange.upperBound...]
            } else {
                let thinkBody = String(afterOpen).trimmingCharacters(in: .whitespacesAndNewlines)
                if !thinkBody.isEmpty {
                    thinkBlocks.append(thinkBody)
                }
                hasUnclosedTag = true
                remaining = ""
                break
            }
        }

        visible += String(remaining)
        return AssistantMessageParts(
            visibleText: visible,
            thinkingText: thinkBlocks.joined(separator: "\n\n"),
            hasUnclosedThinkTag: hasUnclosedTag
        )
    }
}

private struct ThreadDrawerView: View {
    @ObservedObject var llamaState: LlamaState
    @Environment(\.dismiss) private var dismiss

    private var accent: Color {
        llamaState.theme.accent.color
    }

    private var background: Color {
        llamaState.theme.backgroundTop.color
    }

    private var text: Color {
        llamaState.theme.assistantText.color
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Conversations") {
                    ForEach(llamaState.sortedThreads) { thread in
                        Button {
                            llamaState.switchToThread(thread.id)
                            dismiss()
                        } label: {
                            HStack(alignment: .top, spacing: 10) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(thread.title)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(text)
                                        .lineLimit(1)

                                    Text(thread.preview)
                                        .font(.caption)
                                        .foregroundStyle(text.opacity(0.68))
                                        .lineLimit(2)
                                }

                                Spacer()

                                if llamaState.activeThreadID == thread.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(accent)
                                }
                            }
                        }
                        .disabled(llamaState.isGenerating)
                    }
                    .onDelete(perform: llamaState.deleteThreads)
                }
            }
            .scrollContentBackground(.hidden)
            .background(background)
            .listStyle(.insetGrouped)
            .navigationTitle("Chats")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        llamaState.createThreadAndSwitch()
                        dismiss()
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(accent)
                    }
                    .disabled(llamaState.isGenerating)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(accent)
                }
            }
        }
        .tint(accent)
        .preferredColorScheme(.dark)
    }
}

private struct ModelDrawerView: View {
    @ObservedObject var llamaState: LlamaState
    @Environment(\.dismiss) private var dismiss
    @State private var memoryDraft = ""

    private var accent: Color {
        llamaState.theme.accent.color
    }

    private var text: Color {
        llamaState.theme.assistantText.color
    }

    private var background: Color {
        llamaState.theme.backgroundTop.color
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Appearance") {
                    ForEach(ThemePreset.allCases) { preset in
                        Button {
                            llamaState.applyThemePreset(preset)
                        } label: {
                            HStack {
                                Text(preset.title)
                                Spacer()
                                if llamaState.theme.preset == preset {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(accent)
                                }
                            }
                        }
                    }

                    ForEach(ThemeColorSlot.allCases) { slot in
                        ColorPicker(
                            slot.title,
                            selection: Binding(
                                get: { llamaState.themeColor(slot) },
                                set: { llamaState.setThemeColor(slot, color: $0) }
                            ),
                            supportsOpacity: false
                        )
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Text Size")
                            Spacer()
                            Text(String(format: "%.2fx", llamaState.theme.fontScale))
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(accent)
                        }
                        Slider(
                            value: Binding(
                                get: { llamaState.theme.fontScale },
                                set: { llamaState.setThemeFontScale($0) }
                            ),
                            in: 0.85...1.35,
                            step: 0.05
                        )
                        .tint(accent)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Bubble Corners")
                            Spacer()
                            Text("\(Int(llamaState.theme.bubbleCornerRadius))")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(accent)
                        }
                        Slider(
                            value: Binding(
                                get: { llamaState.theme.bubbleCornerRadius },
                                set: { llamaState.setThemeBubbleCornerRadius($0) }
                            ),
                            in: 10...28,
                            step: 1
                        )
                        .tint(accent)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Input Corners")
                            Spacer()
                            Text("\(Int(llamaState.theme.inputCornerRadius))")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(accent)
                        }
                        Slider(
                            value: Binding(
                                get: { llamaState.theme.inputCornerRadius },
                                set: { llamaState.setThemeInputCornerRadius($0) }
                            ),
                            in: 10...24,
                            step: 1
                        )
                        .tint(accent)
                    }

                    Button("Reset To Black & Gold") {
                        llamaState.resetTheme()
                    }
                }

                Section("Runtime") {
                    HStack {
                        Text("Current model")
                        Spacer()
                        Text(llamaState.currentModelName)
                            .foregroundStyle(accent)
                            .multilineTextAlignment(.trailing)
                    }

                    Toggle("Default /no_think for user messages", isOn: $llamaState.useNoThinkByDefault)
                        .tint(accent)

                    Button("Run Benchmark") {
                        Task {
                            await llamaState.runBench()
                        }
                    }

                    Button("Unload Model", role: .destructive) {
                        llamaState.unloadModel()
                    }
                    .disabled(!llamaState.isModelLoaded)
                }

                Section("Memory") {
                    HStack(spacing: 8) {
                        TextField("Add global memory note", text: $memoryDraft)
                            .textFieldStyle(.roundedBorder)
                        Button("Add") {
                            llamaState.addGlobalMemoryNote(memoryDraft)
                            memoryDraft = ""
                        }
                        .disabled(memoryDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }

                    if !llamaState.globalMemoryNotes.isEmpty {
                        ForEach(Array(llamaState.globalMemoryNotes.enumerated()), id: \.offset) { _, note in
                            Text(note)
                                .foregroundStyle(text)
                        }
                        .onDelete(perform: llamaState.deleteGlobalMemoryNotes)
                    } else {
                        Text("No global notes yet. Use /remember <fact> in chat or add here.")
                            .font(.footnote)
                            .foregroundStyle(text.opacity(0.72))
                    }

                    if !llamaState.activeThreadMemoryNotes.isEmpty {
                        Text("Active thread memory")
                            .font(.caption)
                            .foregroundStyle(accent)
                        ForEach(Array(llamaState.activeThreadMemoryNotes.enumerated()), id: \.offset) { _, note in
                            Text(note)
                                .font(.footnote)
                                .foregroundStyle(text.opacity(0.88))
                        }
                    }

                    Button("Clear Active Thread Memory", role: .destructive) {
                        llamaState.clearActiveThreadMemory()
                    }
                    .disabled(llamaState.activeThreadMemoryNotes.isEmpty)
                }

                Section("Import / Download") {
                    InputButton(llamaState: llamaState)
                    LoadCustomButton(llamaState: llamaState)
                }

                Section("Downloaded Models") {
                    ForEach(llamaState.downloadedModels) { model in
                        DownloadButton(
                            llamaState: llamaState,
                            modelName: model.name,
                            modelUrl: model.url,
                            filename: model.filename
                        )
                    }
                    .onDelete(perform: llamaState.deleteDownloadedModels)
                }

                Section("Recommended Qwen Models") {
                    ForEach(llamaState.undownloadedModels) { model in
                        DownloadButton(
                            llamaState: llamaState,
                            modelName: model.name,
                            modelUrl: model.url,
                            filename: model.filename
                        )
                    }
                }

                Section("Diagnostics") {
                    Text(llamaState.messageLog)
                        .font(.footnote.monospaced())
                        .foregroundStyle(text.opacity(0.86))
                        .textSelection(.enabled)
                }
            }
            .scrollContentBackground(.hidden)
            .background(background)
            .listStyle(.insetGrouped)
            .navigationTitle("Model Settings")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(accent)
                }
            }
        }
        .tint(accent)
        .preferredColorScheme(.dark)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
