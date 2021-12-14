import DateProvider
import DeveloperDirLocator
import Dispatch
import FileSystem
import EmceeLogging
import Foundation
import MetricsExtensions
import DeveloperDirLocator
import PluginManager
import Tmp
import UniqueIdentifierGenerator
import SynchronousWaiter
import QueueModels

public final class RunnerProviderImpl: RunnerProvider {
    private let dateProvider: DateProvider
    private let developerDirLocator: DeveloperDirLocator
    private let fileSystem: FileSystem
    private let logger: ContextualLogger
    private let pluginEventBusProvider: PluginEventBusProvider
    private let runnerWasteCollectorProvider: RunnerWasteCollectorProvider
    private let specificMetricRecorder: SpecificMetricRecorder
    private let tempFolder: TemporaryFolder
    private let testRunnerProvider: TestRunnerProvider
    private let testTimeoutCheckInterval: DispatchTimeInterval
    private let uniqueIdentifierGenerator: UniqueIdentifierGenerator
    private let version: Version
    private let waiter: Waiter
    
    public init(
        dateProvider: DateProvider,
        developerDirLocator: DeveloperDirLocator,
        fileSystem: FileSystem,
        logger: ContextualLogger,
        pluginEventBusProvider: PluginEventBusProvider,
        runnerWasteCollectorProvider: RunnerWasteCollectorProvider,
        specificMetricRecorder: SpecificMetricRecorder,
        tempFolder: TemporaryFolder,
        testRunnerProvider: TestRunnerProvider,
        testTimeoutCheckInterval: DispatchTimeInterval,
        uniqueIdentifierGenerator: UniqueIdentifierGenerator,
        version: Version,
        waiter: Waiter
    ) {
        self.dateProvider = dateProvider
        self.developerDirLocator = developerDirLocator
        self.fileSystem = fileSystem
        self.logger = logger
        self.pluginEventBusProvider = pluginEventBusProvider
        self.runnerWasteCollectorProvider = runnerWasteCollectorProvider
        self.specificMetricRecorder = specificMetricRecorder
        self.tempFolder = tempFolder
        self.testRunnerProvider = testRunnerProvider
        self.testTimeoutCheckInterval = testTimeoutCheckInterval
        self.uniqueIdentifierGenerator = uniqueIdentifierGenerator
        self.version = version
        self.waiter = waiter
    }
    
    public func create(
        specificMetricRecorder: SpecificMetricRecorder
    ) -> Runner {
        return Runner(
            dateProvider: dateProvider,
            developerDirLocator: developerDirLocator,
            fileSystem: fileSystem,
            logger: logger,
            pluginEventBusProvider: pluginEventBusProvider,
            runnerWasteCollectorProvider: runnerWasteCollectorProvider,
            specificMetricRecorder: specificMetricRecorder,
            tempFolder: tempFolder,
            testRunnerProvider: testRunnerProvider,
            testTimeoutCheckInterval: testTimeoutCheckInterval,
            uniqueIdentifierGenerator: uniqueIdentifierGenerator,
            version: version,
            waiter: waiter
        )
    }
}
