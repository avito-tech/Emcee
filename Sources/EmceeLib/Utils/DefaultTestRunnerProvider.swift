import Foundation
import Models
import ResourceLocationResolver
import Runner
import fbxctest

public final class DefaultTestRunnerProvider: TestRunnerProvider {
    private let resourceLocationResolver: ResourceLocationResolver

    public init(resourceLocationResolver: ResourceLocationResolver) {
        self.resourceLocationResolver = resourceLocationResolver
    }

    public func testRunner(testRunnerTool: TestRunnerTool) throws -> TestRunner {
        switch testRunnerTool {
        case .fbxctest(let fbxctestLocation):
            return FbxctestBasedTestRunner(
                fbxctestLocation: fbxctestLocation,
                resourceLocationResolver: resourceLocationResolver
            )
        }
    }
}

