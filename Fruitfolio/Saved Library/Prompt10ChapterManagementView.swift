import SwiftUI

/// Edits the same library store used by Ask destinations and Guide Builder.
struct Prompt10ChapterManagementView: View {
    @ObservedObject var store: Prompt10SavedLibraryStore
    let encyclopediaID: UUID
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var motion: MotionPreferences
    @State private var editing: Prompt10Chapter?
    @State private var name = ""
    @State private var showingEditor = false
    @State private var deleting: Prompt10Chapter?
    @State private var error: String?

    private var chapters: [Prompt10Chapter] {
        store.encyclopedia(id: encyclopediaID)?.chapters.sorted { $0.order < $1.order } ?? []
    }

    var body: some View {
        ZStack {
            DesignTokens.ColorToken.backgroundCream.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    BackControl { dismiss() }
                    Text("my chapters").font(.custom("Chalkboard SE", size: 22, relativeTo: .title2)).bold()
                    FruitfolioControlPillButton(label: "add chapter") {
                        editing = nil; name = ""; error = nil; showingEditor = true
                    }
                    ForEach(chapters) { chapter in
                        VStack(alignment: .leading, spacing: 10) {
                            Text(chapter.name).bold().fixedSize(horizontal: false, vertical: true)
                            Text("\(chapter.pages.count) saved pages")
                            Button("rename chapter") {
                                editing = chapter; name = chapter.name; error = nil; showingEditor = true
                            }.frame(minHeight: 44)
                            Button("delete chapter") { deleting = chapter }.frame(minHeight: 44)
                            ForEach(chapter.pages.sorted { $0.order < $1.order }) { page in
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(page.question).fixedSize(horizontal: false, vertical: true)
                                    Menu("move page") {
                                        ForEach(chapters.filter { $0.id != chapter.id }) { destination in
                                            Button(destination.name) {
                                                do {
                                                    try store.movePage(encyclopediaID: encyclopediaID, pageID: page.id,
                                                        fromChapterID: chapter.id, toChapterID: destination.id)
                                                } catch { self.error = error.localizedDescription }
                                            }
                                        }
                                    }
                                    .disabled(chapters.count < 2)
                                    .frame(minHeight: 44)
                                    .accessibilityLabel("move page: " + page.question)
                                }
                            }
                        }.padding(.vertical, 8)
                    }
                    if let error { Text(error).accessibilityIdentifier("chapters.error") }
                }
                .font(.custom("Chalkboard SE", size: 16, relativeTo: .body))
                .foregroundStyle(DesignTokens.ColorToken.primaryBurgundy)
                .padding(20).frame(maxWidth: 580).frame(maxWidth: .infinity)
            }
            .fruitfolioModalBlur(active: showingEditor || deleting != nil, reduceMotion: motion.reduceMotionActive)
            if showingEditor {
                Prompt10WatercolorPopup {
                    VStack(spacing: 16) {
                        Text(editing == nil ? "add chapter" : "rename chapter").bold()
                        TextField("chapter name", text: $name)
                            .textFieldStyle(.roundedBorder).submitLabel(.done)
                            .accessibilityIdentifier("chapters.name")
                        if let error { Text(error) }
                        FruitfolioControlPillButton(label: "save chapter", action: save)
                        WatercolorSecondaryButton(label: "cancel") { showingEditor = false }
                    }
                    .font(.custom("Chalkboard SE", size: 16, relativeTo: .body))
                    .foregroundStyle(DesignTokens.ColorToken.primaryBurgundy)
                }
            }
            if let deleting {
                Prompt12ConfirmationPopup(assetName: "popup_warning", title: "delete chapter?",
                    message: "this removes the chapter and its saved pages from this encyclopedia.",
                    primaryLabel: "keep chapter", secondaryLabel: nil, destructiveLabel: "delete chapter",
                    primaryAction: { self.deleting = nil }, secondaryAction: nil, destructiveAction: {
                        do { try store.deleteChapter(encyclopediaID: encyclopediaID, chapterID: deleting.id); self.deleting = nil }
                        catch { self.error = error.localizedDescription; self.deleting = nil }
                    })
            }
        }
        .interactiveDismissDisabled(showingEditor || deleting != nil)
    }

    private func save() {
        do {
            if let editing { try store.renameChapter(encyclopediaID: encyclopediaID, chapterID: editing.id, to: name) }
            else { try store.createChapter(in: encyclopediaID, name: name) }
            showingEditor = false; error = nil
        } catch { self.error = error.localizedDescription }
    }
}
