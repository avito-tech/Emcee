import Foundation

@objc(PrincipalClass)
final class EntryPoint: NSObject {

    public override init() {
        super.init()
        main()
    }

    func main() {
        let exportPath = ProcessInfo.processInfo.environment["AVITO_TEST_RUNNER_RUNTIME_TESTS_EXPORT_PATH"]

        if let exportPath = exportPath, !exportPath.isEmpty {
            TestQuery(outputPath: exportPath).export()
        }
    }
}
