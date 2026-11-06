import Foundation

/// User-controlled material is never an approved Research Library source.
nonisolated struct Prompt10UserMaterialProvenance: Codable, Equatable, Sendable {
    var sourceURL: String?
    let addedAt: Date
    var editedAt: Date
}

nonisolated struct Prompt10UserMaterialDraft: Equatable, Sendable {
    var title = ""
    var body = ""
    var sourceURL = ""
    var notes = ""
    static let maximumBodyLength = 100_000
    static let maximumNotesLength = 50_000

    enum Failure: LocalizedError {
        case emptyBody, tooLong, invalidSourceURL, immutableEvidence
        var errorDescription: String? {
            switch self {
            case .emptyBody: return "add your own text before saving this page."
            case .tooLong: return "keep the page under 100,000 characters and notes under 50,000 characters."
            case .invalidSourceURL: return "use a complete http or https source address without a login, or leave the source field blank."
            case .immutableEvidence: return "saved Ask evidence stays unchanged. add a separate page for your own material."
            }
        }
    }

    init() {}
    init(page: Prompt10SavedPage) {
        title = page.question
        body = page.answer
        sourceURL = page.userMaterial?.sourceURL ?? ""
        notes = page.notes
    }
    var hasContent: Bool { !title.isEmpty || !body.isEmpty || !sourceURL.isEmpty || !notes.isEmpty }

    func page(chapterID: UUID, existing: Prompt10SavedPage? = nil, now: Date = Date()) throws -> Prompt10SavedPage {
        let name = try Prompt10BookLabelPolicy.title(title)
        guard !body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw Failure.emptyBody }
        guard body.count <= Self.maximumBodyLength, notes.count <= Self.maximumNotesLength else { throw Failure.tooLong }
        let address = sourceURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if !address.isEmpty {
            guard address.count <= 4096, !address.contains(where: { $0.isWhitespace }),
                  let components = URLComponents(string: address),
                  ["http", "https"].contains(components.scheme?.lowercased() ?? ""),
                  let host = components.host, !host.isEmpty, components.user == nil, components.password == nil,
                  components.url != nil else { throw Failure.invalidSourceURL }
        }
        if let existing, existing.userMaterial == nil { throw Failure.immutableEvidence }
        var page = existing ?? Prompt10SavedPage(chapterID: chapterID, question: name, answer: body, saveType: .fullAnswer)
        page.chapterID = chapterID
        page.question = name
        page.answer = body
        page.notes = notes
        page.updatedAt = now
        page.userMaterial = .init(sourceURL: address.isEmpty ? nil : address,
                                  addedAt: existing?.userMaterial?.addedAt ?? now, editedAt: now)
        return page
    }
}

/// Freeze only fields this editor can change. Independently attached images
/// and other retained metadata remain owned by the current saved page.
nonisolated struct Prompt10UserMaterialEditingBaseline: Equatable, Sendable {
    let pageID: UUID
    let chapterID: UUID
    let draft: Prompt10UserMaterialDraft
    init(page: Prompt10SavedPage) {
        pageID = page.id
        chapterID = page.chapterID
        draft = Prompt10UserMaterialDraft(page: page)
    }
    func matches(_ page: Prompt10SavedPage) -> Bool {
        page.id == pageID && page.chapterID == chapterID && page.userMaterial != nil
            && Prompt10UserMaterialDraft(page: page) == draft
    }
}

nonisolated enum Prompt10ImageAttachmentMutation {
    static func attaching(_ newID: String, replacing oldID: String?, to current: [String]) throws -> [String] {
        guard !newID.isEmpty, !current.contains(newID) else { throw Prompt10LibraryError.persistenceFailure }
        var result = current
        if let oldID {
            guard let index = result.firstIndex(of: oldID) else { throw Prompt10LibraryError.pageNotFound }
            result[index] = newID
        } else { result.append(newID) }
        return result
    }
}
