import AppleTools
import DateProvider
import Foundation
import Models
import ResourceLocationResolver
import Runner
import fbxctest

public final class DefaultTestRunnerProvider: TestRunnerProvider {
    private let dateProvider: DateProvider
    private let resourceLocationResolver: ResourceLocationResolver

    public init(
        dateProvider: DateProvider,
        resourceLocationResolver: ResourceLocationResolver
    ) {
        self.dateProvider = dateProvider
        self.resourceLocationResolver = resourceLocationResolver
    }

    public func testRunner(testRunnerTool: TestRunnerTool) throws -> TestRunner {
        switch testRunnerTool {
        case .fbxctest(let fbxctestLocation):
            return FbxctestBasedTestRunner(
                fbxctestLocation: fbxctestLocation,
                resourceLocationResolver: resourceLocationResolver
            )
        case .xcodebuild:
            return XcodebuildBasedTestRunner(
                dateProvider: dateProvider,
                resourceLocationResolver: resourceLocationResolver
            )
        }
    }
}

