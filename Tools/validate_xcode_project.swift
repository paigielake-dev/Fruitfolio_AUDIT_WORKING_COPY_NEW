import Foundation

let path = CommandLine.arguments.dropFirst().first ?? "Fruitfolio.xcodeproj/project.pbxproj"
let data = try Data(contentsOf: URL(fileURLWithPath: path))
let root = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as! [String: Any]
let objects = root["objects"] as! [String: [String: Any]]
let project = objects[root["rootObject"] as! String]!
for targetID in project["targets"] as! [String] {
    guard let target = objects[targetID] else { fatalError("Missing target \(targetID)") }
    for phaseID in target["buildPhases"] as! [String] {
        guard let phase = objects[phaseID] else { fatalError("Missing build phase \(phaseID)") }
        for fileID in phase["files"] as? [String] ?? [] {
            guard let file = objects[fileID], let ref = file["fileRef"] as? String,
                  objects[ref] != nil else { fatalError("Unresolved build file \(fileID)") }
        }
    }
}
let llama = objects.values.filter { ($0["name"] as? String) == "llama.xcframework" }
precondition(llama.count == 1, "One intentional llama runtime reference is required")
precondition(llama[0]["sourceTree"] as? String == "<group>", "Native runtime must use a repository-relative path")
precondition(llama[0]["path"] as? String == "Fruitfolio/Frameworks/llama.xcframework")
print("Xcode project parsed; target build-file references resolved. No Xcode build/link was performed.")
