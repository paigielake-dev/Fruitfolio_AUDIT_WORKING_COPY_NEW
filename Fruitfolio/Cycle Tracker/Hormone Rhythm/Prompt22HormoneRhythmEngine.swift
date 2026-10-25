import Foundation

nonisolated struct Prompt22HormoneRhythmEngine: Sendable {
    func presentation(
        for input: Prompt22HormoneRhythmInput
    ) -> Prompt22HormoneRhythmPresentation {
        let markerX = contextMarkerX(for: input)
        let contextNote = contextNote(for: input)

        return Prompt22HormoneRhythmPresentation(
            title: "hormone rhythm",
            subtitle: "general patterns, not measured hormone levels ♡",
            contextNote: contextNote,
            sections: Prompt22Hormone.allCases.map { hormone in
                section(
                    for: hormone,
                    input: input,
                    markerX: markerX
                )
            },
            showsContextMarker: markerX != nil
        )
    }

    private func section(
        for hormone: Prompt22Hormone,
        input: Prompt22HormoneRhythmInput,
        markerX: Double?
    ) -> Prompt22HormoneSectionPresentation {
        let approvedCopy = input.copyByHormone[hormone]
        let summary = approvedCopy?.summary.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        let resolvedSummary: String
        if let summary, !summary.isEmpty {
            resolvedSummary = summary
        } else {
            resolvedSummary = fallbackSummary(for: hormone)
        }

        let pattern = educationalPattern(for: hormone)
        let marker = markerX.flatMap { x in
            educationalCurveY(at: x, in: pattern).map { y in
                Prompt22ContextMarker(
                    x: x,
                    y: y,
                    confidence: input.confidence
                )
            }
        }

        let markerAccessibility = marker == nil
            ? ""
            : " A marker shows estimated cycle-timeline position only; its vertical placement follows this educational drawing and is not a measured hormone level."

        return Prompt22HormoneSectionPresentation(
            hormone: hormone,
            assetName: assetName(for: hormone),
            title: hormone.rawValue,
            summary: resolvedSummary,
            accessibilitySummary:
                "\(hormone.rawValue.capitalized): general educational pattern. " +
                "\(resolvedSummary) This is not a measured \(hormone.rawValue) level." +
                markerAccessibility,
            pattern: pattern,
            marker: marker,
            researchIDs: approvedCopy?.researchIDs ?? []
        )
    }

    /// These normalized coordinates are presentation geometry only.
    /// They are never physiological measurements, percentages, concentrations,
    /// hormone ratios, or user records.
    func educationalPattern(
        for hormone: Prompt22Hormone
    ) -> [Prompt22NormalizedPoint] {
        switch hormone {
        case .estrogen:
            return [
                .init(x: 0.00, y: 0.28),
                .init(x: 0.16, y: 0.24),
                .init(x: 0.34, y: 0.42),
                .init(x: 0.50, y: 0.82),
                .init(x: 0.58, y: 0.38),
                .init(x: 0.72, y: 0.55),
                .init(x: 0.88, y: 0.40),
                .init(x: 1.00, y: 0.24)
            ]

        case .progesterone:
            return [
                .init(x: 0.00, y: 0.18),
                .init(x: 0.24, y: 0.18),
                .init(x: 0.48, y: 0.20),
                .init(x: 0.58, y: 0.30),
                .init(x: 0.72, y: 0.78),
                .init(x: 0.86, y: 0.68),
                .init(x: 1.00, y: 0.22)
            ]

        case .testosterone:
            return [
                .init(x: 0.00, y: 0.43),
                .init(x: 0.18, y: 0.44),
                .init(x: 0.36, y: 0.47),
                .init(x: 0.52, y: 0.56),
                .init(x: 0.68, y: 0.49),
                .init(x: 0.84, y: 0.46),
                .init(x: 1.00, y: 0.43)
            ]
        }
    }

    /// Uses the existing Prompt 17 cycle-progress output when available. This
    /// consumes prediction data; it does not calculate or modify prediction math.
    /// When that upstream progress is unavailable, the prior conservative
    /// semantic-context anchors remain as the fallback.
    func contextMarkerX(
        for input: Prompt22HormoneRhythmInput
    ) -> Double? {
        guard input.personalizationPermitted else {
            return nil
        }

        // Explicit altered-cycle contexts remain conservative regardless of
        // timeline data. Prompt 27A may also suppress the rendered marker.
        guard input.context != .alteredNaturalCycleContext else {
            return nil
        }

        // Prompt 17's normalized current-cycle position is the preferred source
        // for the marker. It remains valid throughout the represented cycle and
        // prevents the marker from disappearing when the upstream semantic title
        // temporarily falls back to the neutral “your cycle today” umbrella.
        if let progress = input.estimatedCycleProgress,
           progress.isFinite {
            return min(1, max(0, progress))
        }

        if let cycleDay = input.cycleDay,
           let estimatedCycleLength = input.estimatedCycleLength,
           cycleDay > 0,
           estimatedCycleLength > 1 {
            let normalized = Double(cycleDay - 1)
                / Double(estimatedCycleLength - 1)
            return min(1, max(0, normalized))
        }

        // Presentation-only educational reference when a real current cycle day
        // exists but Prompt 17 does not yet have enough completed history to
        // estimate an individualized cycle length. This never enters prediction
        // models and is never described as the user's biological cycle length.
        if let cycleDay = input.cycleDay, cycleDay > 0 {
            let educationalReferenceLength = 28.0
            return min(1, max(0, Double(cycleDay - 1) / (educationalReferenceLength - 1)))
        }

        switch input.context {
        case .insufficient, .alteredNaturalCycleContext:
            return nil
        case .menstruation:
            return 0.08
        case .follicularEarly:
            return 0.28
        case .follicularLater:
            return 0.44
        case .estimatedOvulation:
            return 0.54
        case .luteal:
            return 0.76
        }
    }

    /// Returns only the y-coordinate of the already-defined educational drawing
    /// at a given x-coordinate. This is linear presentation interpolation, not a
    /// hormone calculation or a physiological estimate.
    func educationalCurveY(
        at markerX: Double,
        in points: [Prompt22NormalizedPoint]
    ) -> Double? {
        guard !points.isEmpty, markerX.isFinite else {
            return nil
        }

        let sorted = points.sorted { $0.x < $1.x }
        let x = min(1, max(0, markerX))

        guard let first = sorted.first,
              let last = sorted.last else {
            return nil
        }

        if x <= first.x {
            return first.y
        }

        if x >= last.x {
            return last.y
        }

        for (left, right) in zip(sorted, sorted.dropFirst()) {
            guard x >= left.x, x <= right.x else {
                continue
            }

            let span = right.x - left.x
            guard span > 0 else {
                return left.y
            }

            let fraction = (x - left.x) / span
            return left.y + (right.y - left.y) * fraction
        }

        return nil
    }

    private func contextNote(
        for input: Prompt22HormoneRhythmInput
    ) -> String? {
        guard input.personalizationPermitted else {
            if input.context == .alteredNaturalCycleContext {
                return "general natural-cycle reference; no current-position marker is shown"
            }
            return nil
        }

        guard contextMarkerX(for: input) != nil else {
            return nil
        }

        return "around where you may be in your cycle"
    }

    private func fallbackSummary(
        for hormone: Prompt22Hormone
    ) -> String {
        switch hormone {
        case .estrogen:
            return "a general educational rhythm across the menstrual cycle"
        case .progesterone:
            return "a separate general educational rhythm across the menstrual cycle"
        case .testosterone:
            return "a distinct, comparatively subtle educational rhythm across the menstrual cycle"
        }
    }

    private func assetName(
        for hormone: Prompt22Hormone
    ) -> String {
        switch hormone {
        case .estrogen:
            return Prompt22HormoneAsset.estrogen
        case .progesterone:
            return Prompt22HormoneAsset.progesterone
        case .testosterone:
            return Prompt22HormoneAsset.testosterone
        }
    }
}
