import SwiftUI

@MainActor
struct Prompt23SymptomsView: View {
    @StateObject private var model: Prompt23SymptomsViewModel
    @EnvironmentObject private var motionPreferences: MotionPreferences
    @EnvironmentObject private var audioManager: AudioManager
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private let contextPolicy: Prompt27AContextPolicyResult
    private let onSaved: (() -> Void)?

    init(
        activeDate: Date = Date(),
        repository: (any Prompt20DailyLogRepository)? = nil,
        ownerID: Prompt20DailyLogOwnerID? = nil,
        contextPolicy: Prompt27AContextPolicyResult = Prompt27AContextPolicyResult(),
        onSaved: (() -> Void)? = nil
    ) {
        _model = StateObject(
            wrappedValue: Prompt23SymptomsViewModel(
                activeDate: activeDate,
                repository: repository,
                ownerID: ownerID
            )
        )
        self.contextPolicy = contextPolicy
        self.onSaved = onSaved
    }

    private var contextClarification: String? {
        Prompt27AContextPresentationCopy.symptomsClarification(
            policy: contextPolicy
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            header

            if let contextClarification {
                Text(contextClarification)
                    .font(Prompt23Type.note)
                    .foregroundStyle(
                        Prompt23Palette.burgundy.opacity(0.70)
                    )
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        Prompt23Palette.burgundy.opacity(0.045),
                        in: RoundedRectangle(
                            cornerRadius: 16,
                            style: .continuous
                        )
                    )
                    .accessibilityLabel(contextClarification)
            }

            if model.isLoading {
                loadingState
            } else if model.isFutureDate {
                futureDateState
            } else {
                symptomGrid
                saveArea
            }
        }
        .frame(maxWidth: 620, alignment: .leading)
        .frame(maxWidth: .infinity, alignment: .center)
        .task {
            await model.loadIfNeeded()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("how are you feeling?")
                .font(Prompt23Type.title)
                .foregroundStyle(Prompt23Palette.burgundy)
                .accessibilityAddTraits(.isHeader)

            Text("tap anything that feels true today ♡")
                .font(Prompt23Type.subtitle)
                .foregroundStyle(Prompt23Palette.burgundy.opacity(0.68))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var loadingState: some View {
        HStack(spacing: 12) {
            Image("symptom_notes")
                .resizable()
                .scaledToFit()
                .frame(width: 44, height: 44)
                .accessibilityHidden(true)

            Text("opening today’s observations…")
                .font(Prompt23Type.body)
                .foregroundStyle(Prompt23Palette.burgundy.opacity(0.72))
        }
        .frame(maxWidth: .infinity, minHeight: 220, alignment: .center)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Loading symptoms")
    }

    private var futureDateState: some View {
        Text("future days stay unrecorded until they arrive ♡")
            .font(Prompt23Type.body)
            .foregroundStyle(Prompt23Palette.burgundy.opacity(0.76))
            .frame(maxWidth: .infinity, minHeight: 220, alignment: .center)
            .multilineTextAlignment(.center)
            .accessibilityLabel("Symptoms cannot be recorded for a future date")
    }

    private var symptomGrid: some View {
        LazyVGrid(
            columns: gridColumns,
            alignment: .center,
            spacing: dynamicTypeSize.isAccessibilitySize ? 28 : 22
        ) {
            ForEach(Prompt23SymptomTaxonomy.items) { item in
                symptomCell(item)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Symptoms")
    }

    private var gridColumns: [GridItem] {
        let count = dynamicTypeSize.isAccessibilitySize ? 2 : 3
        return Array(
            repeating: GridItem(.flexible(minimum: 72), spacing: 14, alignment: .top),
            count: count
        )
    }

    private func symptomCell(_ item: Prompt23SymptomItem) -> some View {
        let selected = model.selectedIDs.contains(item.symptomID)

        return Button {
            audioManager.play(.buttonSoftPop)
            withOptionalSelectionAnimation {
                model.toggle(item.symptomID)
            }
        } label: {
            VStack(spacing: 7) {
                ZStack {
                    if selected {
                        Prompt23WatercolorRing()
                            .stroke(
                                Prompt23Palette.burgundy.opacity(0.54),
                                style: StrokeStyle(
                                    lineWidth: 2.4,
                                    lineCap: .round,
                                    lineJoin: .round
                                )
                            )
                            .frame(width: 67, height: 63)
                            .transition(.opacity)
                            .accessibilityHidden(true)
                    }

                    Prompt23SymptomArtwork(assetNames: item.assetNames)
                        .frame(width: 58, height: 52)
                        .accessibilityHidden(true)

                    if selected {
                        Image("control_check")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 19, height: 19)
                            .offset(x: 25, y: -23)
                            .transition(.opacity.combined(with: .scale(scale: 0.92)))
                            .accessibilityHidden(true)
                    }
                }
                .frame(width: 74, height: 68)

                Text(item.displayLabel)
                    .font(Prompt23Type.label)
                    .foregroundStyle(
                        Prompt23Palette.burgundy.opacity(selected ? 0.96 : 0.78)
                    )
                    .multilineTextAlignment(.center)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, minHeight: 104, alignment: .top)
            .contentShape(Rectangle())
        }
        .buttonStyle(
            Prompt23SoftPressButtonStyle(
                reduceMotion: motionPreferences.reduceMotionActive
            )
        )
        .disabled(model.isLoading || model.isFutureDate || model.saveState == .saving)
        .accessibilityLabel(item.displayLabel)
        .accessibilityValue(selected ? "selected" : "not selected")
        .accessibilityHint("Double tap to \(selected ? "deselect" : "select")")
    }

    private var saveArea: some View {
        VStack(alignment: .leading, spacing: 9) {
            Button {
                audioManager.play(.buttonSoftPop)
                Task {
                    let didSave = await model.save()
                    if didSave {
                        onSaved?()
                    }
                }
            } label: {
                ZStack {
                    Image("button_coral")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 185)
                        .accessibilityHidden(true)

                    Text(model.saveState == .saving ? "saving…" : "save today")
                        .font(Prompt23Type.save)
                        .foregroundStyle(Prompt23Palette.burgundy)
                }
                .frame(minHeight: 48)
            }
            .buttonStyle(
                Prompt23SoftPressButtonStyle(
                    reduceMotion: motionPreferences.reduceMotionActive
                )
            )
            .disabled(!model.canSave)
            .opacity(model.canSave || model.saveState == .saving ? 1 : 0.54)
            .accessibilityLabel(model.saveState == .saving ? "Saving symptoms" : "Save symptoms")

            switch model.saveState {
            case .saved:
                Text("saved to your day ♡")
                    .font(Prompt23Type.note)
                    .foregroundStyle(Prompt23Palette.burgundy.opacity(0.72))
                    .transition(.opacity)
            case .failed:
                Text("that didn’t save yet — your choices are still here")
                    .font(Prompt23Type.note)
                    .foregroundStyle(Prompt23Palette.burgundy.opacity(0.78))
                    .fixedSize(horizontal: false, vertical: true)
            case .idle, .saving:
                EmptyView()
            }
        }
        .padding(.top, 2)
        .animation(
            motionPreferences.reduceMotionActive ? nil : .easeOut(duration: 0.20),
            value: model.saveState
        )
    }

    private func withOptionalSelectionAnimation(_ changes: () -> Void) {
        if motionPreferences.reduceMotionActive {
            changes()
        } else {
            withAnimation(.easeOut(duration: 0.22)) {
                changes()
            }
        }
    }
}

private struct Prompt23SymptomArtwork: View {
    let assetNames: [String]

    var body: some View {
        Group {
            if assetNames.count == 1, let assetName = assetNames.first {
                Image(assetName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 52, height: 52)
            } else {
                HStack(spacing: -8) {
                    ForEach(Array(assetNames.enumerated()), id: \.offset) { index, assetName in
                        Image(assetName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 34, height: 34)
                            .rotationEffect(.degrees(index == 0 ? -4 : 4))
                            .offset(y: index == 0 ? 2 : -2)
                    }
                }
                .frame(width: 58, height: 52)
            }
        }
        .allowsHitTesting(false)
    }
}

private struct Prompt23WatercolorRing: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let inset = rect.insetBy(dx: 3.0, dy: 3.5)
        path.move(to: CGPoint(x: inset.midX, y: inset.minY + 0.7))
        path.addCurve(
            to: CGPoint(x: inset.maxX - 0.8, y: inset.midY),
            control1: CGPoint(x: inset.maxX * 0.73, y: inset.minY - 0.7),
            control2: CGPoint(x: inset.maxX + 0.6, y: inset.height * 0.30)
        )
        path.addCurve(
            to: CGPoint(x: inset.midX - 0.5, y: inset.maxY - 0.4),
            control1: CGPoint(x: inset.maxX + 0.4, y: inset.height * 0.75),
            control2: CGPoint(x: inset.width * 0.74, y: inset.maxY + 1.0)
        )
        path.addCurve(
            to: CGPoint(x: inset.minX + 0.7, y: inset.midY + 0.4),
            control1: CGPoint(x: inset.width * 0.28, y: inset.maxY + 0.4),
            control2: CGPoint(x: inset.minX - 0.5, y: inset.height * 0.72)
        )
        path.addCurve(
            to: CGPoint(x: inset.midX, y: inset.minY + 0.7),
            control1: CGPoint(x: inset.minX - 0.7, y: inset.height * 0.28),
            control2: CGPoint(x: inset.width * 0.28, y: inset.minY - 0.4)
        )
        return path
    }
}

private struct Prompt23SoftPressButtonStyle: ButtonStyle {
    let reduceMotion: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(
                reduceMotion
                    ? 1
                    : (configuration.isPressed ? 0.965 : 1)
            )
            .offset(
                y: reduceMotion
                    ? 0
                    : (configuration.isPressed ? 1.5 : 0)
            )
            .rotationEffect(
                .degrees(
                    reduceMotion
                        ? 0
                        : (configuration.isPressed ? -0.25 : 0)
                )
            )
            .brightness(
                configuration.isPressed
                    ? -0.04
                    : 0
            )
            .animation(
                reduceMotion
                    ? nil
                    : .spring(response: 0.22, dampingFraction: 0.70),
                value: configuration.isPressed
            )
    }
}

private enum Prompt23Palette {
    static let burgundy = Color(red: 128.0 / 255.0, green: 0, blue: 0)
}

private enum Prompt23Type {
    static let title = Font.custom("Chalkboard SE", size: 25, relativeTo: .title2).weight(.bold)
    static let subtitle = Font.custom("Chalkboard SE", size: 13, relativeTo: .subheadline)
    static let label = Font.custom("Chalkboard SE", size: 12, relativeTo: .caption)
    static let body = Font.custom("Chalkboard SE", size: 14, relativeTo: .body)
    static let note = Font.custom("Chalkboard SE", size: 12, relativeTo: .caption)
    static let save = Font.custom("Chalkboard SE", size: 14, relativeTo: .body).weight(.semibold)
}
