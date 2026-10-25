import SwiftUI

// Exact Prompt 10 physical SavedLibrary asset set.
// Keep all names centralized; do not scatter filename strings through the UI.

enum Prompt10SavedLibraryAsset: String, CaseIterable {
    case bookOpen = "library_book_open"
    case label = "library_label"
    case flower = "library_flower"
    case bookBlank = "library_book_blank"
    case bookshelf = "library_bookshelf"
    case openBook = "library_open_book"
    case bookClosed = "library_book_closed"
    case pottedPlant = "library_potted_plant"
    case bookYellow = "library_book_yellow"
    case bookmark = "library_bookmark"
    case bookPink = "library_book_pink"
    case bookSage = "library_book_sage"
    case bookStack = "library_book_stack"
    case bookCoral = "library_book_coral"
    case flowerBundle = "library_flower_bundle"
    case bookLavender = "library_book_lavender"

    static let exactPhysicalFilenames: [String] = [
        "library_book_open.png",
        "library_label.png",
        "library_flower.png",
        "library_book_blank.png",
        "library_bookshelf.png",
        "library_open_book.png",
        "library_book_closed.png",
        "library_potted_plant.png",
        "library_book_yellow.png",
        "library_bookmark.png",
        "library_book_pink.png",
        "library_book_sage.png",
        "library_book_stack.png",
        "library_book_coral.png",
        "library_flower_bundle.png",
        "library_book_lavender.png"
    ]
}

struct Prompt10LibraryAssetImage: View {
    let asset: Prompt10SavedLibraryAsset
    var accessibilityLabel: String? = nil

    var body: some View {
        Image(asset.rawValue)
            .resizable()
            .scaledToFit()
            .accessibilityHidden(accessibilityLabel == nil)
            .accessibilityLabel(accessibilityLabel ?? "")
    }
}
