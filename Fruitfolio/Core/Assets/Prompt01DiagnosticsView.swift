import SwiftUI

#if DEBUG
struct Prompt01DiagnosticsView: View {
    @State private var report = "Tap Validate Assets"

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(report)
                    .font(.system(.footnote, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
                    .padding()
            }
            .navigationTitle("Prompt 01 Diagnostics")
            .toolbar {
                Button("Validate Assets") {
                    let result = FruitfolioAssetValidator.validate()
                    report = result.consoleReport()
                    print(report)
                }
            }
        }
    }
}
#endif
