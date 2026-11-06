import Foundation
import SwiftParser
import SwiftSyntax

/// Bounded read-only source invariant: app SwiftUI alert/confirmationDialog
/// calls use the shared presenter. This is not UI/typecheck/accessibility proof.
private struct Finding: Codable {
    let path: String
    let method: String
    let line: Int
    let column: Int
}
private final class Visitor: SyntaxVisitor {
    private let path: String
    private let locations: SourceLocationConverter
    var findings: [Finding] = []
    init(path: String, tree: SourceFileSyntax) {
        self.path = path
        locations = SourceLocationConverter(fileName: path, tree: tree)
        super.init(viewMode: .sourceAccurate)
    }
    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        if let member = node.calledExpression.as(MemberAccessExprSyntax.self),
           ["alert", "confirmationDialog"].contains(member.declName.baseName.text) {
            let location = locations.location(for: member.declName.baseName.positionAfterSkippingLeadingTrivia)
            findings.append(.init(path: path, method: member.declName.baseName.text,
                                  line: location.line, column: location.column))
        }
        return .visitChildren
    }
}

@main
private enum Main {
    static func main() {
        let paths = Array(Set(CommandLine.arguments.dropFirst())).sorted()
        guard !paths.isEmpty else {
            FileHandle.standardError.write(Data("usage: shared-confirmation-check SWIFT_FILES...\n".utf8))
            exit(2)
        }
        do {
            var findings: [Finding] = []
            for path in paths {
                let source = try String(contentsOfFile: path, encoding: .utf8)
                let tree = Parser.parse(source: source)
                guard !tree.hasError else { throw CocoaError(.fileReadCorruptFile) }
                let visitor = Visitor(path: path, tree: tree)
                visitor.walk(tree)
                findings += visitor.findings
            }
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            FileHandle.standardOutput.write(try encoder.encode(findings))
            FileHandle.standardOutput.write(Data("\n".utf8))
            exit(findings.isEmpty ? 0 : 1)
        } catch {
            FileHandle.standardError.write(Data("confirmation source check failed; no clean result was produced: \(error)\n".utf8))
            exit(2)
        }
    }
}
