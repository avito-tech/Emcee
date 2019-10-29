import Foundation
import Models

public enum RuntimeDumpModeInputValidationError: Error, CustomStringConvertible {
    case missingAppBundleToPerformApplicationTestRuntimeDump(XcTestBundle)
    public var description: String {
        switch self {
        case .missingAppBundleToPerformApplicationTestRuntimeDump(let xcTestBundle):
            return "Cannot perform runtime dump in application test mode: test bundle \(xcTestBundle) requires application bundle to be provided, but build artifacts do not contain location of app bundle"
        }
    }
}

public final class RuntimeDumpModeDeterminer {
    public static func runtimeDumpMode(testArgFileEntry: TestArgFile.Entry) throws -> RuntimeDumpMode {
        switch testArgFileEntry.buildArtifacts.xcTestBundle.runtimeDumpKind {
        case .logicTest:
            return .logicTest
        case .appTest:
            guard let appLocation = testArgFileEntry.buildArtifacts.appBundle else {
                throw RuntimeDumpModeInputValidationError.missingAppBundleToPerformApplicationTestRuntimeDump(testArgFileEntry.buildArtifacts.xcTestBundle)
            }
            return .appTest(
                RuntimeDumpApplicationTestSupport(
                    appBundle: appLocation,
                    simulatorControlTool: testArgFileEntry.toolResources.simulatorControlTool
                )
            )
        }
    }
}
