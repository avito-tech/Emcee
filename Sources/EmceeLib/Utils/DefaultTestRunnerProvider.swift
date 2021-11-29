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
    private let xcResultTool: XcResultTool

    public init(
        dateProvider: DateProvider,
        fileSystem: FileSystem,
        processControllerProvider: ProcessControllerProvider,
        resourceLocationResolver: ResourceLocationResolver,
        xcResultTool: XcResultTool
    ) {
        self.dateProvider = dateProvider
        self.fileSystem = fileSystem
        self.processControllerProvider = processControllerProvider
        self.resourceLocationResolver = resourceLocationResolver
        self.xcResultTool = xcResultTool
    }

    public func testRunner() throws -> TestRunner {
        return XcodebuildBasedTestRunner(
            dateProvider: dateProvider,
            fileSystem: fileSystem,
            processControllerProvider: processControllerProvider,
            resourceLocationResolver: resourceLocationResolver,
            xcResultTool: xcResultTool
        )
    }
}

