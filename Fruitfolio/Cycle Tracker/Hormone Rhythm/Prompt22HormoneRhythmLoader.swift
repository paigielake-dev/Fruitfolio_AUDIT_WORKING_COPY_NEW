import Foundation

/// Phase 22 consumes the semantic Cycle Tracker context already established
/// upstream. It does not calculate a new cycle phase, fertile window, ovulation
/// date, confidence score, hormone state, or laboratory value.
@MainActor
struct Prompt22HormoneRhythmLoader {
    var bodyBiologyLoader = Prompt21BodyBiologyLoader()

    /// Optional bridge to already-approved Research Library copy. Keeping this
    /// injectable avoids inventing a second Research/RAG architecture.
    var approvedCopyProvider:
        (@Sendable (Prompt22Hormone, Prompt22HormoneRhythmInput) async -> Prompt22HormoneEducationalCopy?)?

    /// Optional upstream permission resolver for altered-cycle contexts.
    /// When absent, Phase 22 remains conservative and only uses the semantic
    /// context that Prompt 21 already accepted as standard cycle context.
    var personalizationPermissionProvider:
        (@Sendable () async -> Bool)?

    func load(
        now: Date = Date()
    ) async throws -> Prompt22HormoneRhythmInput {
        async let bodyInputTask = bodyBiologyLoader.load(now: now)
        async let predictionTask = loadExistingPrompt17Prediction(now: now)

        let bodyInput = try await bodyInputTask
        let prediction = try await predictionTask
        let mapped = Self.mapBodyContext(bodyInput.state)
        let resolvedCycleDay = prediction?.currentCycleDay ?? bodyInput.cycleDay
        let hasRepresentedCyclePosition =
            prediction?.currentCycleProgress != nil || resolvedCycleDay != nil
        let permitted = await resolvedPersonalizationPermission(
            for: mapped,
            hasRepresentedCyclePosition: hasRepresentedCyclePosition
        )

        var base = Prompt22HormoneRhythmInput(
            context:
                permitted
                    ? mapped
                    : (
                        mapped == .insufficient
                            ? .insufficient
                            : .alteredNaturalCycleContext
                    ),
            contextKind: Self.mapContextKind(bodyInput.contextKind),
            cycleDay: resolvedCycleDay,
            estimatedCycleLength: prediction?.estimatedCycleLength,
            estimatedCycleProgress: prediction?.currentCycleProgress,
            confidence: prediction.map {
                Self.mapPredictionConfidence($0.predictionConfidence)
            } ?? Self.mapConfidence(
                upstreamTitle: bodyInput.upstreamContextTitle
            ),
            personalizationPermitted: permitted,
            measuredHormoneDataAvailable: false
        )

        guard let approvedCopyProvider else {
            return base
        }

        var copyByHormone: [
            Prompt22Hormone: Prompt22HormoneEducationalCopy
        ] = [:]

        for hormone in Prompt22Hormone.allCases {
            if let approved = await approvedCopyProvider(hormone, base) {
                copyByHormone[hormone] = approved
            }
        }

        base = Prompt22HormoneRhythmInput(
            context: base.context,
            contextKind: base.contextKind,
            cycleDay: base.cycleDay,
            estimatedCycleLength: base.estimatedCycleLength,
            estimatedCycleProgress: base.estimatedCycleProgress,
            confidence: base.confidence,
            personalizationPermitted: base.personalizationPermitted,
            measuredHormoneDataAvailable: false,
            copyByHormone: copyByHormone
        )

        return base
    }

    /// Reads the same stored cycle-start history and Prompt 14 fallback dates
    /// already used by the app, then asks the unchanged Prompt 17 engine for its
    /// existing currentCycleProgress output. Phase 22 never edits Prompt 17 or
    /// derives a competing prediction.
    private func loadExistingPrompt17Prediction(
        now: Date
    ) async throws -> Prompt17CyclePredictionResult? {
        let todayLoader = bodyBiologyLoader.todayLoader

        async let archiveTask = todayLoader.cycleStore.snapshot()
        async let onboardingTask = todayLoader.onboardingStore.snapshot()

        let archive = try await archiveTask
        let onboarding = try await onboardingTask

        let storedCycleStarts = archive.cycleStarts
            .filter { !$0.metadata.isDeleted }
            .map(\.date)

        let sourceCycleStarts = storedCycleStarts.isEmpty
            ? onboarding.allSuppliedCycleStarts
            : storedCycleStarts

        guard !sourceCycleStarts.isEmpty else {
            return nil
        }

        let cycleStartDates = try sourceCycleStarts.map {
            try Self.foundationDate(
                from: $0,
                calendar: todayLoader.calendar
            )
        }

        let periodRecords = try Self.explicitPeriodRecords(
            onboarding: onboarding,
            calendar: todayLoader.calendar
        )

        return Prompt17CyclePredictionEngine(
            calendar: todayLoader.calendar
        )
        .calculate(
            from: Prompt17CyclePredictionInput(
                cycleStartDates: cycleStartDates,
                periodRecords: periodRecords,
                asOfDate: now
            )
        )
    }

    private static func explicitPeriodRecords(
        onboarding: Prompt14OnboardingDraft,
        calendar: Calendar
    ) throws -> [Prompt17RecordedPeriod] {
        guard onboarding.latestPeriodState == .supplied,
              let localStart = onboarding.latestPeriodStart else {
            return []
        }

        let start = try foundationDate(
            from: localStart,
            calendar: calendar
        )

        let end: Date?
        if onboarding.currentPeriodAnswer == .no,
           onboarding.periodEndState == .supplied,
           let localEnd = onboarding.periodEnd {
            end = try foundationDate(
                from: localEnd,
                calendar: calendar
            )
        } else {
            end = nil
        }

        return [
            Prompt17RecordedPeriod(
                startDate: start,
                endDate: end
            )
        ]
    }

    private static func foundationDate(
        from local: Prompt13LocalDate,
        calendar: Calendar
    ) throws -> Date {
        var components = DateComponents()
        components.calendar = calendar
        components.timeZone = calendar.timeZone
        components.year = local.year
        components.month = local.month
        components.day = local.day
        components.hour = 12

        guard let date = calendar.date(from: components) else {
            throw Prompt13CycleError.invalidDate
        }

        let check = calendar.dateComponents(
            [.year, .month, .day],
            from: date
        )

        guard check.year == local.year,
              check.month == local.month,
              check.day == local.day else {
            throw Prompt13CycleError.invalidDate
        }

        return date
    }

    private func resolvedPersonalizationPermission(
        for context: Prompt22CycleContext,
        hasRepresentedCyclePosition: Bool
    ) async -> Bool {
        if let personalizationPermissionProvider {
            return await personalizationPermissionProvider()
        }

        // A real Prompt 17 cycle-progress value is sufficient to place the
        // timeline marker even when Prompt 21 is using its neutral umbrella
        // title (for example, immediately after an explicitly ended period).
        // No phase or hormone level is inferred here.
        return context != .insufficient || hasRepresentedCyclePosition
    }

    nonisolated static func mapBodyContext(
        _ state: Prompt21BodyBiologyState
    ) -> Prompt22CycleContext {
        switch state {
        case .neutral:
            return .insufficient
        case .follicularEarly:
            return .follicularEarly
        case .follicularLater:
            return .follicularLater
        case .estimatedOvulation:
            return .estimatedOvulation
        case .luteal:
            return .luteal
        case .menstruation:
            return .menstruation
        }
    }

    nonisolated static func mapContextKind(
        _ kind: Prompt21BodyBiologyContextKind
    ) -> Prompt22ContextKind {
        switch kind {
        case .educational:
            return .educational
        case .calculated:
            return .calculated
        case .estimated:
            return .estimated
        }
    }

    nonisolated static func mapPredictionConfidence(
        _ confidence: Prompt17PredictionConfidence
    ) -> Prompt22Confidence {
        switch confidence {
        case .limitedEstimate:
            return .limited
        case .developingEstimate:
            return .developing
        case .strongEstimate:
            return .strong
        }
    }

    nonisolated static func mapConfidence(
        upstreamTitle: String
    ) -> Prompt22Confidence {
        let normalized = upstreamTitle.lowercased()

        if normalized.contains("limited") {
            return .limited
        }
        if normalized.contains("developing") {
            return .developing
        }
        if normalized.contains("strong") {
            return .strong
        }

        return .unavailable
    }
}

