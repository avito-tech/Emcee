import AppleTools
import DateProvider
import Foundation
import ProcessController
import ResourceLocationResolver
import Runner
import RunnerModels
import fbxctest

public final class DefaultTestRunnerProvider: TestRunnerProvider {
    private let dateProvider: DateProvider
    private let processControllerProvider: ProcessControllerProvider
    private let resourceLocationResolver: ResourceLocationResolver

    public init(
        dateProvider: DateProvider,
        processControllerProvider: ProcessControllerProvider,
        resourceLocationResolver: ResourceLocationResolver
    ) {
        self.dateProvider = dateProvider
        self.processControllerProvider = processControllerProvider
        self.resourceLocationResolver = resourceLocationResolver
    }

    public func testRunner(testRunnerTool: TestRunnerTool) throws -> TestRunner {
        switch testRunnerTool {
        case .fbxctest(let fbxctestLocation):
            return FbxctestBasedTestRunner(
                fbxctestLocation: fbxctestLocation,
                processControllerProvider: processControllerProvider,
                resourceLocationResolver: resourceLocationResolver
            )
        case .xcodebuild(let xctestJsonLocation):
            return XcodebuildBasedTestRunner(
                xctestJsonLocation: xctestJsonLocation,
                dateProvider: dateProvider,
                processControllerProvider: processControllerProvider,
                resourceLocationResolver: resourceLocationResolver
            )
        }
    }
}

