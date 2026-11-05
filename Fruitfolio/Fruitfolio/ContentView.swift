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
        if ProcessInfo.processInfo.arguments.contains("-fruitfolioModalQA") {
            Prompt1BModalRegressionHarness()
        } else {
            Prompt03SkeletonView()
        }
        #else
        Prompt03SkeletonView()
        #endif
    }
}
