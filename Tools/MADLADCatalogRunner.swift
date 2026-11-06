import Foundation

/// CLI adapter around the exact application translation service/runtime.
/// Inputs are catalog UI strings, never user health records.
@main
struct MADLADCatalogRunner {
    struct Job: Decodable {
        let id: String
        let source: String
        let locale: String
        let protectedLiterals: [String]
    }
    struct Result: Encodable {
        let id: String
        let value: String?
        let error: String?
    }
    static func main() async {
        guard CommandLine.arguments.count == 2 else {
            FileHandle.standardError.write(Data("usage: MADLADCatalogRunner RESOURCE_DIRECTORY\n".utf8))
            exit(2)
        }
        let runtime = FruitfolioMADLADRuntime(resourceDirectory: URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true))
        let service = FruitfolioTranslationService(runtime: runtime)
        while let line = readLine() {
            do {
                let job = try JSONDecoder().decode(Job.self, from: Data(line.utf8))
                let result: Result
                do {
                    guard let language = FruitfolioLanguage(rawValue: job.locale) else {
                        throw FruitfolioTranslationError.unsupportedLanguage(job.locale)
                    }
                    let value = try await service.translate(job.source, language: language, protectedLiterals: job.protectedLiterals)
                    result = Result(id: job.id, value: value, error: nil)
                } catch {
                    result = Result(id: job.id, value: nil, error: error.localizedDescription)
                }
                var encoded = try JSONEncoder().encode(result)
                encoded.append(0x0a)
                FileHandle.standardOutput.write(encoded)
            } catch {
                FileHandle.standardError.write(Data("invalid catalog request: \(error.localizedDescription)\n".utf8))
                exit(2)
            }
        }
    }
}
