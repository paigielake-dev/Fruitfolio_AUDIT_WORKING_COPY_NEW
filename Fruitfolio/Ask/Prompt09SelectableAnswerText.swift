import SwiftUI
import UIKit

/// Read-only native text selection for completed Ask answers.
/// The selected range is surfaced to SwiftUI so Prompt 09 can offer `save selection ♡`
/// without making the sourced Fruitfolio answer itself editable.
struct Prompt09SelectableAnswerText: UIViewRepresentable {
    let text: String
    @Binding var selectedText: String?

    func makeCoordinator() -> Coordinator {
        Coordinator(selectedText: $selectedText)
    }

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.isEditable = false
        textView.isSelectable = true
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainer.widthTracksTextView = true
        textView.textContainer.heightTracksTextView = false
        textView.textContainer.lineBreakMode = .byWordWrapping
        textView.textContainer.maximumNumberOfLines = 0
        textView.adjustsFontForContentSizeCategory = true
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textView.tintColor = UIColor(
            red: 244.0 / 255.0,
            green: 199.0 / 255.0,
            blue: 199.0 / 255.0,
            alpha: 1
        )
        applyText(to: textView)
        return textView
    }

    func updateUIView(_ textView: UITextView, context: Context) {
        context.coordinator.selectedText = $selectedText

        if textView.text != text {
            applyText(to: textView)
            selectedText = nil
        }
    }

    func sizeThatFits(
        _ proposal: ProposedViewSize,
        uiView: UITextView,
        context: Context
    ) -> CGSize? {
        guard let width = proposal.width else { return nil }
        let safeWidth = max(1, width)
        uiView.textContainer.size = CGSize(
            width: safeWidth,
            height: .greatestFiniteMagnitude
        )
        let size = uiView.sizeThatFits(
            CGSize(width: safeWidth, height: .greatestFiniteMagnitude)
        )
        return CGSize(width: safeWidth, height: ceil(size.height))
    }

    private func applyText(to textView: UITextView) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = 4

        let baseFont = UIFont(name: "ChalkboardSE-Regular", size: 16)
            ?? UIFont.preferredFont(forTextStyle: .body)

        textView.attributedText = NSAttributedString(
            string: text,
            attributes: [
                .font: UIFontMetrics(forTextStyle: .body).scaledFont(for: baseFont),
                .foregroundColor: UIColor(
                    red: 128.0 / 255.0,
                    green: 0,
                    blue: 0,
                    alpha: 1
                ),
                .paragraphStyle: paragraph
            ]
        )
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        var selectedText: Binding<String?>

        init(selectedText: Binding<String?>) {
            self.selectedText = selectedText
        }

        func textViewDidChangeSelection(_ textView: UITextView) {
            let range = textView.selectedRange
            guard range.location != NSNotFound, range.length > 0 else {
                selectedText.wrappedValue = nil
                return
            }

            guard let swiftRange = Range(range, in: textView.text) else {
                selectedText.wrappedValue = nil
                return
            }

            let value = String(textView.text[swiftRange])
                .trimmingCharacters(in: .whitespacesAndNewlines)
            selectedText.wrappedValue = value.isEmpty ? nil : value
        }
    }
}
