import SwiftUI

/// Reuses the actual onboarding question views, one question at a time. Opening
/// an existing answer never clears completion or forces the whole wizard again.
struct Prompt14CycleSetupEditor: View {
    let onBack: () -> Void
    var store: Prompt14CycleOnboardingStore = .shared
    @State private var selected: Prompt14OnboardingStep?

    private var steps: [Prompt14OnboardingStep] {
        Prompt14OnboardingStep.allCases.filter { $0 != .intro && $0 != .complete }
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            BackControl(action: onBack)
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("edit cycle setup").font(.title2).bold().accessibilityAddTraits(.isHeader)
                    Text("open any answer to add, change, or remove it. you don’t need to repeat setup. your separate daily logs remain unchanged.")
                    ForEach(steps, id: \.rawValue) { step in
                        FruitfolioControlPillButton(label: title(step)) { selected = step }
                            .accessibilityIdentifier("cycleSetup.edit." + step.rawValue)
                    }
                }.frame(maxWidth: 620, alignment: .leading).frame(maxWidth: .infinity)
            }
            .accessibilityIdentifier("cycleSetup.sections")
        }
        .padding(20)
        .font(.custom("Chalkboard SE", size: 16, relativeTo: .body))
        .foregroundStyle(DesignTokens.ColorToken.primaryBurgundy)
        .background(DesignTokens.ColorToken.backgroundCream.ignoresSafeArea())
        .fullScreenCover(isPresented: Binding(get: { selected != nil }, set: { if !$0 { selected = nil } })) {
            if let selected {
                Prompt14CycleOnboardingView(store: store, editingStep: selected) { self.selected = nil }
            }
        }
    }
    private func title(_ step: Prompt14OnboardingStep) -> String {
        switch step {
        case .latestPeriod: return "latest period start"
        case .currentPeriod: return "current period"
        case .periodEnd: return "period end"
        case .previousHistory: return "previous period history"
        case .subjectiveRegularity: return "cycle regularity"
        case .cycleAffectingContext: return "cycle-affecting context"
        case .recentContext: return "recent context"
        case .trackingPreferences: return "tracking preferences"
        case .fertilityEstimates: return "fertility estimate preference"
        case .bbtSetup: return "BBT setup"
        case .cervicalFluidSetup: return "cervical-fluid setup"
        case .intro, .complete: return "cycle setup"
        }
    }
}
