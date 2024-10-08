import AppleTools
import DateProvider
import EmceeLogging
import FileSystem
import Foundation
import HostnameProvider
import ProcessController
import QueueModels
import ResourceLocationResolver
import Runner

public final class DefaultTestRunnerProvider: TestRunnerProvider {
    private let dateProvider: DateProvider
    private let fileSystem: FileSystem
    private let hostnameProvider: HostnameProvider
    private let processControllerProvider: ProcessControllerProvider
    private let resourceLocationResolver: ResourceLocationResolver
    private let version: Version
    private let xcResultTool: XcResultTool

    public init(
        dateProvider: DateProvider,
        fileSystem: FileSystem,
        hostnameProvider: HostnameProvider,
        processControllerProvider: ProcessControllerProvider,
        resourceLocationResolver: ResourceLocationResolver,
        version: Version,
        xcResultTool: XcResultTool
    ) {
        self.dateProvider = dateProvider
        self.fileSystem = fileSystem
        self.hostnameProvider = hostnameProvider
        self.processControllerProvider = processControllerProvider
        self.resourceLocationResolver = resourceLocationResolver
        self.version = version
        self.xcResultTool = xcResultTool
    }

    public func testRunner() throws -> TestRunner {
        return XcodebuildBasedTestRunner(
            dateProvider: dateProvider,
            fileSystem: fileSystem,
            host: hostnameProvider.hostname,
            processControllerProvider: processControllerProvider,
            resourceLocationResolver: resourceLocationResolver,
            version: version,
            xcResultTool: xcResultTool
        )
    }
}

