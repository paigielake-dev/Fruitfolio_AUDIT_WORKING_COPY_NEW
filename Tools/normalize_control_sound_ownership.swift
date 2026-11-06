import Foundation
import SwiftParser
import SwiftSyntax

/// Developer source migration/check only. Uses the toolchain's actual Swift
/// syntax tree; never matches comments/strings or removes other cue types.
private struct Finding: Codable {
    let path: String
    let control: String
    let line: Int
    let start: Int
    let end: Int
}
private final class ControlVisitor: SyntaxVisitor {
    let path: String
    let locations: SourceLocationConverter
    var findings: [Finding] = []
    // These controls own one buttonSoftPop directly or through the canonical
    // pill. Other Buttons and distinct operation/modal cues remain untouched.
    private let owners: Set<String> = ["FruitfolioControlPillButton", "WatercolorPrimaryButton", "WatercolorSecondaryButton", "BackControl", "CloseControl", "Prompt28WatercolorButton", "Prompt28MiniControlPill", "Prompt12NavigationRow"]
    init(path: String, tree: SourceFileSyntax) {
        self.path = path
        locations = SourceLocationConverter(fileName: path, tree: tree)
        super.init(viewMode: .sourceAccurate)
    }
    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        guard let callee = node.calledExpression.as(DeclReferenceExprSyntax.self),
              owners.contains(callee.baseName.text) else { return .visitChildren }
        var closures: [ClosureExprSyntax] = []
        if let trailing = node.trailingClosure { closures.append(trailing) }
        for argument in node.arguments {
            if let closure = argument.expression.as(ClosureExprSyntax.self) { closures.append(closure) }
        }
        for closure in closures {
            for statement in closure.statements {
                guard let call = statement.item.as(FunctionCallExprSyntax.self),
                      let member = call.calledExpression.as(MemberAccessExprSyntax.self), member.declName.baseName.text == "play",
                      let receiver = member.base?.as(DeclReferenceExprSyntax.self), receiver.baseName.text == "audioManager",
                      call.arguments.count == 1, let argument = call.arguments.first,
                      let cue = argument.expression.as(MemberAccessExprSyntax.self), cue.base == nil,
                      cue.declName.baseName.text == "buttonSoftPop" else { continue }
                findings.append(Finding(path: path, control: callee.baseName.text,
                    line: locations.location(for: statement.positionAfterSkippingLeadingTrivia).line,
                    start: statement.positionAfterSkippingLeadingTrivia.utf8Offset,
                    end: statement.endPositionBeforeTrailingTrivia.utf8Offset))
            }
        }
        return .visitChildren
    }
}
@main
private struct ControlSoundOwnership {
    static func main() {
        do { try run() }
        catch {
            FileHandle.standardError.write(Data("control sound source operation failed: \(error.localizedDescription)\n".utf8))
            exit(2)
        }
    }
    private static func run() throws {
        var arguments = Array(CommandLine.arguments.dropFirst())
        let apply = arguments.contains("--apply")
        let check = arguments.contains("--check")
        arguments.removeAll { $0 == "--apply" || $0 == "--check" }
        guard !arguments.isEmpty, !(apply && check) else {
            FileHandle.standardError.write(Data("usage: control-sound-ownership [--check | --apply] SWIFT_FILES...\n".utf8))
            exit(2)
        }
        var files: [(URL, Data, [Finding])] = []
        for name in arguments {
            let url = URL(fileURLWithPath: name)
            let data = try Data(contentsOf: url)
            guard let text = String(data: data, encoding: .utf8) else { throw CocoaError(.fileReadInapplicableStringEncoding) }
            let tree = Parser.parse(source: text)
            guard !tree.hasError else {
                FileHandle.standardError.write(Data("Swift parser found syntax errors; no source modified: \(name)\n".utf8))
                exit(2)
            }
            let visitor = ControlVisitor(path: name, tree: tree)
            visitor.walk(tree)
            files.append((url, data, visitor.findings))
        }
        if apply {
            // All files parse before any mutation; preserve caller comments and
            // reject a source changed concurrently after its captured snapshot.
            for (url, original, findings) in files where !findings.isEmpty {
                guard try Data(contentsOf: url) == original else { throw CocoaError(.fileWriteFileExists) }
                var bytes = Array(original)
                for finding in findings.sorted(by: { $0.start > $1.start }) {
                    var start = finding.start, end = finding.end
                    let lineStart = (bytes[..<start].lastIndex(of: 10).map { $0 + 1 }) ?? 0
                    let lineEnd = bytes[end...].firstIndex(of: 10) ?? bytes.count
                    let whitespace: (UInt8) -> Bool = { $0 == 32 || $0 == 9 || $0 == 13 }
                    if bytes[lineStart..<start].allSatisfy(whitespace), bytes[end..<lineEnd].allSatisfy(whitespace) {
                        start = lineStart
                        end = lineEnd < bytes.count ? lineEnd + 1 : lineEnd
                    }
                    bytes.removeSubrange(start..<end)
                }
                let permissions = try FileManager.default.attributesOfItem(atPath: url.path)[.posixPermissions]
                try Data(bytes).write(to: url, options: .atomic)
                if let permissions { try FileManager.default.setAttributes([.posixPermissions: permissions], ofItemAtPath: url.path) }
            }
        }
        let findings = files.flatMap { $0.2 }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        var report = try encoder.encode(findings)
        report.append(10)
        FileHandle.standardOutput.write(report)
        if check && !findings.isEmpty { exit(1) }
    }
}
