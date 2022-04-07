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
import Zip

public final class DefaultTestRunnerProvider: TestRunnerProvider {
    private let dateProvider: DateProvider
    private let fileSystem: FileSystem
    private let hostnameProvider: HostnameProvider
    private let processControllerProvider: ProcessControllerProvider
    private let resourceLocationResolver: ResourceLocationResolver
    private let version: Version
    private let xcResultTool: XcResultTool
    private let zipCompressor: ZipCompressor

    public init(
        dateProvider: DateProvider,
        fileSystem: FileSystem,
        hostnameProvider: HostnameProvider,
        processControllerProvider: ProcessControllerProvider,
        resourceLocationResolver: ResourceLocationResolver,
        version: Version,
        xcResultTool: XcResultTool,
        zipCompressor: ZipCompressor
    ) {
        self.dateProvider = dateProvider
        self.fileSystem = fileSystem
        self.hostnameProvider = hostnameProvider
        self.processControllerProvider = processControllerProvider
        self.resourceLocationResolver = resourceLocationResolver
        self.version = version
        self.xcResultTool = xcResultTool
        self.zipCompressor = zipCompressor
    }

    public func testRunner() throws -> TestRunner {
        return XcodebuildBasedTestRunner(
            dateProvider: dateProvider,
            fileSystem: fileSystem,
            host: hostnameProvider.hostname,
            processControllerProvider: processControllerProvider,
            resourceLocationResolver: resourceLocationResolver,
            version: version,
            xcResultTool: xcResultTool,
            zipCompressor: zipCompressor
        )
    }
}

