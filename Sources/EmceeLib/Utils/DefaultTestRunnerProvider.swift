import AppleTools
import DateProvider
import EmceeLogging
import FileSystem
import Foundation
import ProcessController
import ResourceLocationResolver
import Runner
import RunnerModels

public final class DefaultTestRunnerProvider: TestRunnerProvider {
    private let dateProvider: DateProvider
    private let fileSystem: FileSystem
    private let processControllerProvider: ProcessControllerProvider
    private let resourceLocationResolver: ResourceLocationResolver

    public init(
        dateProvider: DateProvider,
        fileSystem: FileSystem,
        processControllerProvider: ProcessControllerProvider,
        resourceLocationResolver: ResourceLocationResolver
    ) {
        self.dateProvider = dateProvider
        self.fileSystem = fileSystem
        self.processControllerProvider = processControllerProvider
        self.resourceLocationResolver = resourceLocationResolver
    }

    public func testRunner(testRunnerTool: TestRunnerTool) throws -> TestRunner {
        switch testRunnerTool {
        case .xcodebuild:
            return XcodebuildBasedTestRunner(
                dateProvider: dateProvider,
                fileSystem: fileSystem,
                processControllerProvider: processControllerProvider,
                resourceLocationResolver: resourceLocationResolver
            )
        }
    }
}

