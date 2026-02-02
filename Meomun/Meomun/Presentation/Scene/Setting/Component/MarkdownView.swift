//
//  MarkdownView.swift
//  Meomun
//
//  Created by hoon on 2/3/26.
//

import SwiftUI

struct MarkdownView: View {
    private let markdown: String

    init(_ markdown: String) {
        self.markdown = markdown
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(parsedBlocks) { block in
                switch block.kind {
                case .header1(let text):
                    inlineBoldText(text)
                        .font(.title2)
                        .bold()

                case .header2(let text):
                    inlineBoldText(text)
                        .font(.headline)
                        .padding(.top, 8)

                case .header3(let text):
                    inlineBoldText(text)
                        .font(.headline)
                        .padding(.top, 8)

                case .paragraph(let text):
                    inlineBoldText(text)
                        .font(.footnote)
                        .foregroundColor(.primary)

                case .bullet(let items):
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                            HStack(alignment: .top, spacing: 8) {
                                Text("•")
                                    .font(.footnote)

                                inlineBoldText(item.text)
                                    .font(.footnote)
                            }
                            // level 0: no indent, level 1+: indent
                            .padding(.leading, CGFloat(max(0, item.level)) * 16)
                        }
                    }

                case .divider:
                    Divider()
                        .padding(.vertical, 4)

                case .spacer:
                    Spacer(minLength: 4)
                }
            }
        }
    }

    private func inlineBoldText(_ text: String) -> Text {
        // Simple support for Markdown bold: **bold**
        // Unmatched ** markers fall back to normal text.
        var result = Text("")
        var remainder = text[...]
        var isBold = false

        while let range = remainder.range(of: "**") {
            let prefix = String(remainder[..<range.lowerBound])
            if !prefix.isEmpty {
                result += isBold ? Text(prefix).bold() : Text(prefix)
            }
            remainder = remainder[range.upperBound...]
            isBold.toggle()
        }

        let tail = String(remainder)
        if !tail.isEmpty {
            result += isBold ? Text(tail).bold() : Text(tail)
        }

        return result
    }

    private var parsedBlocks: [MarkdownBlock] {
        let lines = markdown
            .replacingOccurrences(of: "\r\n", with: "\n")
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map(String.init)

        var blocks: [MarkdownBlock] = []
        var i = 0

        func flushParagraph(_ buffer: inout [String]) {
            let text = buffer.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
            if !text.isEmpty {
                blocks.append(.init(kind: .paragraph(text)))
            }
            buffer.removeAll(keepingCapacity: true)
        }

        while i < lines.count {
            let rawLine = lines[i]
            let line = rawLine.trimmingCharacters(in: .whitespaces)

            // Divider
            if line == "---" || line == "—" || line == "___" {
                var empty: [String] = []
                flushParagraph(&empty)
                blocks.append(.init(kind: .divider))
                i += 1
                continue
            }

            // Headings
            if line.hasPrefix("# ") {
                blocks.append(.init(kind: .header1(String(line.dropFirst(2)))))
                i += 1
                continue
            }

            if line.hasPrefix("## ") {
                blocks.append(.init(kind: .header2(String(line.dropFirst(3)))))
                i += 1
                continue
            }

            if line.hasPrefix("### ") {
                blocks.append(.init(kind: .header3(String(line.dropFirst(4)))))
                i += 1
                continue
            }

            // Bullet list (collect consecutive "- " lines, preserving indentation level)
            if line.hasPrefix("- ") {
                var items: [(level: Int, text: String)] = []

                while i < lines.count {
                    let currentRaw = lines[i]
                    let currentTrimmed = currentRaw.trimmingCharacters(in: .whitespaces)

                    // Stop if this line is not a bullet
                    guard currentTrimmed.hasPrefix("- ") else { break }

                    // Count leading spaces (indentation) BEFORE trimming
                    let leadingSpaces = currentRaw.prefix { $0 == " " }.count
                    // Treat 2 spaces as one nesting level (common in markdown)
                    let level = leadingSpaces / 2

                    let text = String(currentTrimmed.dropFirst(2))
                    items.append((level: level, text: text))
                    i += 1
                }

                blocks.append(.init(kind: .bullet(items)))
                continue
            }

            // Blank line -> spacer
            if line.isEmpty {
                blocks.append(.init(kind: .spacer))
                i += 1
                continue
            }

            // Paragraph (collect until blank / heading / bullet / divider)
            var paragraphBuffer: [String] = [line]
            i += 1
            while i < lines.count {
                let next = lines[i].trimmingCharacters(in: .whitespaces)
                let nextTrimmed = next.trimmingCharacters(in: .whitespaces)
                if nextTrimmed.isEmpty
                    || nextTrimmed.hasPrefix("# ")
                    || nextTrimmed.hasPrefix("## ")
                    || nextTrimmed.hasPrefix("### ")
                    || nextTrimmed.hasPrefix("- ")
                    || nextTrimmed == "---"
                    || nextTrimmed == "___"
                    || nextTrimmed == "—" {
                    break
                }
                paragraphBuffer.append(next)
                i += 1
            }
            flushParagraph(&paragraphBuffer)
        }

        // Clean up consecutive spacers
        var compact: [MarkdownBlock] = []
        for block in blocks {
            if case .spacer = block.kind,
                compact.last?.kind.isSpacer ?? false {
                continue
            }
            compact.append(block)
        }
        return compact
    }
}

// MARK: - MarkdownBlock

private struct MarkdownBlock: Identifiable {
    enum Kind {
        case header1(String)
        case header2(String)
        case header3(String)
        case paragraph(String)
        case bullet([(level: Int, text: String)])
        case divider
        case spacer

        var isSpacer: Bool {
            if case .spacer = self { return true }
            return false
        }
    }

    let id = UUID()
    let kind: Kind
}

private extension Text {
    static func += (lhs: inout Text, rhs: Text) {
        lhs = lhs + rhs
    }
}
