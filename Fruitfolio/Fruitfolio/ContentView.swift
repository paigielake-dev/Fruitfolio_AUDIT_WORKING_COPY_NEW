import SwiftUI

struct ContentView: View {
    #if DEBUG
    @StateObject private var regressionPreferences = FruitfolioRegressionPreferenceSuite()
    private var isRegressionRun: Bool {
        let flags = ["-fruitfolioSettingsControlsQA", "-fruitfolioAccountActionQA", "-fruitfolioCycleModalQA", "-fruitfolioMeasurementsQA", "-fruitfolioLibraryStorageQA", "-fruitfolioContextStorageQA", "-fruitfolioDataManagementQA", "-fruitfolioCitationQA", "-fruitfolioGameQA", "-fruitfolioContactQA", "-fruitfolioWheelQA", "-fruitfolioPersonalHealthQA", "-fruitfolioHormoneLibraryQA", "-fruitfolioBookQA",
                     "-fruitfolioAskPaperQA", "-fruitfolioTourQA", "-fruitfolioModalQA"]
        return flags.contains(where: ProcessInfo.processInfo.arguments.contains)
    }
    #endif

    var body: some View {
        #if DEBUG
        if isRegressionRun {
            if let defaults = regressionPreferences.defaults {
                // All regression routes receive the real shell's environment
                // objects, backed by a disposable preferences/context suite.
                Prompt03SkeletonView(defaults: defaults)
            } else {
                Text("UI regression environment could not be created.")
            }
        } else { Prompt03SkeletonView() }
        #else
        Prompt03SkeletonView()
        #endif
    }
}
