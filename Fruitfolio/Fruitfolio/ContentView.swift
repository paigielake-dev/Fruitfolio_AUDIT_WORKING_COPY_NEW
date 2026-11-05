//
//  ContentView.swift
//  Fruitfolio
//
//  Created by Paige Lake on 9/1/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-fruitfolioBookQA") {
            Prompt1BBookRegressionHarness()
        } else if ProcessInfo.processInfo.arguments.contains("-fruitfolioAskPaperQA") {
            Prompt09AskView(viewModel: .paperRegressionFixture())
        } else if ProcessInfo.processInfo.arguments.contains("-fruitfolioTourQA") {
            Prompt1BTourRegressionHarness()
        } else if ProcessInfo.processInfo.arguments.contains("-fruitfolioModalQA") {
            Prompt1BModalRegressionHarness()
        } else {
            Prompt03SkeletonView()
        }
        #else
        Prompt03SkeletonView()
        #endif
    }
}
