#if canImport(UIKit)
import SwiftUI
import UIKit

/// Exports an existing file URL without constructing a second archive-sized Data.
struct FruitfolioDataExportPicker: UIViewControllerRepresentable {
    let url: URL
    let onComplete: (Bool) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onComplete: onComplete) }
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let controller = UIDocumentPickerViewController(forExporting: [url], asCopy: true)
        controller.delegate = context.coordinator
        return controller
    }
    func updateUIViewController(_ controller: UIDocumentPickerViewController, context: Context) {}

    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        private let onComplete: (Bool) -> Void
        private var finished = false
        init(onComplete: @escaping (Bool) -> Void) { self.onComplete = onComplete }
        private func finish(_ saved: Bool) {
            guard !finished else { return }
            finished = true
            onComplete(saved)
        }
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) { finish(!urls.isEmpty) }
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) { finish(false) }
    }
}
#endif
