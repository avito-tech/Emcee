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
    private let testRunnerProvider: TestRunnerProvider
    private let uniqueIdentifierGenerator: UniqueIdentifierGenerator
    private let waiter: Waiter
    
    public init(
        dateProvider: DateProvider,
        developerDirLocator: DeveloperDirLocator,
        fileSystem: FileSystem,
        logger: ContextualLogger,
        pluginEventBusProvider: PluginEventBusProvider,
        runnerWasteCollectorProvider: RunnerWasteCollectorProvider,
        testRunnerProvider: TestRunnerProvider,
        uniqueIdentifierGenerator: UniqueIdentifierGenerator,
        waiter: Waiter
    ) {
        self.dateProvider = dateProvider
        self.developerDirLocator = developerDirLocator
        self.fileSystem = fileSystem
        self.logger = logger
        self.pluginEventBusProvider = pluginEventBusProvider
        self.runnerWasteCollectorProvider = runnerWasteCollectorProvider
        self.testRunnerProvider = testRunnerProvider
        self.uniqueIdentifierGenerator = uniqueIdentifierGenerator
        self.waiter = waiter
    }
    
    public func create(
        specificMetricRecorder: SpecificMetricRecorder,
        tempFolder: TemporaryFolder,
        version: Version
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
            uniqueIdentifierGenerator: uniqueIdentifierGenerator,
            version: version,
            waiter: waiter
        )
    }
}
