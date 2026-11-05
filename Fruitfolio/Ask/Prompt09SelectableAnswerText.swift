import SwiftUI
import UIKit

/// Read-only native text selection for completed Ask answers.
/// The selected range is surfaced to SwiftUI so Prompt 09 can offer `save selection ♡`
/// without making the sourced Fruitfolio answer itself editable.
struct Prompt09SelectableAnswerText: UIViewRepresentable {
    let text: String
    @Binding var selectedText: String?
    @Binding var selectedRange: NSRange?
    @Binding var selectedSemanticSpans: [FruitfolioSemanticSpan]?
    @Binding var selectedLanguage: String?
    let renderedLanguage: String

    init(text: String, selectedText: Binding<String?>, selectedRange: Binding<NSRange?> = .constant(nil),
         selectedSemanticSpans: Binding<[FruitfolioSemanticSpan]?> = .constant(nil),
         selectedLanguage: Binding<String?> = .constant(nil), renderedLanguage: String = "en") {
        self.text = text
        self._selectedText = selectedText
        self._selectedRange = selectedRange
        self._selectedSemanticSpans = selectedSemanticSpans
        self._selectedLanguage = selectedLanguage
        self.renderedLanguage = renderedLanguage
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(selectedText: $selectedText, selectedRange: $selectedRange,
                    selectedSemanticSpans: $selectedSemanticSpans, selectedLanguage: $selectedLanguage,
                    renderedLanguage: renderedLanguage)
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
        context.coordinator.renderedSource = text
        context.coordinator.renderedSize = context.environment.dynamicTypeSize
        return textView
    }

    func updateUIView(_ textView: UITextView, context: Context) {
        context.coordinator.selectedText = $selectedText
        context.coordinator.selectedRange = $selectedRange
        context.coordinator.selectedSemanticSpans = $selectedSemanticSpans
        context.coordinator.selectedLanguage = $selectedLanguage
        context.coordinator.renderedLanguage = renderedLanguage

        if context.coordinator.renderedSource != text ||
            context.coordinator.renderedSize != context.environment.dynamicTypeSize {
            applyText(to: textView)
            context.coordinator.renderedSource = text
            context.coordinator.renderedSize = context.environment.dynamicTypeSize
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
        let baseFont = UIFont(name: "ChalkboardSE-Regular", size: 16)
            ?? UIFont.systemFont(ofSize: 16)
        textView.attributedText = FruitfolioSemanticRenderer.attributed(
            markdown: text,
            font: UIFontMetrics(forTextStyle: .body).scaledFont(for: baseFont),
            color: UIColor(red: 128.0 / 255.0, green: 0, blue: 0, alpha: 1)
        )
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        var selectedRange: Binding<NSRange?>
        var selectedSemanticSpans: Binding<[FruitfolioSemanticSpan]?>
        var selectedLanguage: Binding<String?>
        var renderedLanguage: String
        var renderedSource: String?
        var renderedSize: DynamicTypeSize?
        var selectedText: Binding<String?>

        init(selectedText: Binding<String?>, selectedRange: Binding<NSRange?>,
             selectedSemanticSpans: Binding<[FruitfolioSemanticSpan]?>, selectedLanguage: Binding<String?>,
             renderedLanguage: String) {
            self.selectedRange = selectedRange
            self.selectedSemanticSpans = selectedSemanticSpans
            self.selectedLanguage = selectedLanguage
            self.renderedLanguage = renderedLanguage
            self.selectedText = selectedText
        }

        func textViewDidChangeSelection(_ textView: UITextView) {
            let range = textView.selectedRange
            guard range.location != NSNotFound, range.length > 0 else {
                selectedRange.wrappedValue = nil
                selectedSemanticSpans.wrappedValue = nil
                selectedLanguage.wrappedValue = nil
                selectedText.wrappedValue = nil
                return
            }

            guard let swiftRange = Range(range, in: textView.text) else {
                selectedRange.wrappedValue = nil
                selectedSemanticSpans.wrappedValue = nil
                selectedLanguage.wrappedValue = nil
                selectedText.wrappedValue = nil
                return
            }

            selectedRange.wrappedValue = range
            selectedLanguage.wrappedValue = renderedLanguage
            selectedSemanticSpans.wrappedValue = FruitfolioSemanticSlices.selection(
                FruitfolioSemanticDocument.spans(from: renderedSource ?? textView.text ?? ""), utf16Range: range)
            let value = String(textView.text[swiftRange])
            selectedText.wrappedValue = value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : value
        }
    }
}
