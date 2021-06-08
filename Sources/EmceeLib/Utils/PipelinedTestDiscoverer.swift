import AtomicModels
import BuildArtifacts
import DI
import EmceeLogging
import Foundation
import QueueModels
import ResourceLocation
import RunnerModels
import TestArgFile
import TestDiscovery
import URLResource

public final class PipelinedTestDiscoverer {
    private let runtimeDumpRemoteCacheProvider: RuntimeDumpRemoteCacheProvider
    private let testDiscoveryQuerier: TestDiscoveryQuerier
    private let urlResource: URLResource
    
    private let downloadQueue = OperationQueue.create(
        name: "dump.downloadQueue",
        maxConcurrentOperationCount: 4,
        qualityOfService: .default
    )
    private let dumpQueue = OperationQueue.create(
        name: "dump.dumpQueue",
        maxConcurrentOperationCount: OperationQueue.defaultMaxConcurrentOperationCount,
        qualityOfService: .default
    )
    
    public init(
        runtimeDumpRemoteCacheProvider: RuntimeDumpRemoteCacheProvider,
        testDiscoveryQuerier: TestDiscoveryQuerier,
        urlResource: URLResource
    ) {
        self.runtimeDumpRemoteCacheProvider = runtimeDumpRemoteCacheProvider
        self.testDiscoveryQuerier = testDiscoveryQuerier
        self.urlResource = urlResource
    }
    
    public func performTestDiscovery(
        logger: ContextualLogger,
        testArgFile: TestArgFile,
        emceeVersion: Version,
        remoteCacheConfig: RuntimeDumpRemoteCacheConfig?
    ) throws -> [[DiscoveredTestEntry]] {        
        let discoveredTests = AtomicValue<[[DiscoveredTestEntry]]>(
            Array(repeating: [], count: testArgFile.entries.count)
        )
        let collectedErrors = AtomicValue<[Error]>([])
        
        let rootOperation = BlockOperation { [logger] in
            logger.debug("Finished pipelined test discovery")
        }
        
        testArgFile.entries.enumerated().forEach { index, testArgFileEntry in
            let downloadOperation = BlockOperation { [urlResource, logger] in
                do {
                    let requiredArtifacts = try testArgFileEntry.buildArtifacts.requiredArtifacts()
                    for artifact in requiredArtifacts {
                        if let url = artifact.url {
                            let handler = BlockingURLResourceHandler()
                            urlResource.fetchResource(url: url, handler: handler, tokens: testArgFileEntry.buildArtifacts.hostsTokens)
                            let path = try handler.wait(limit: 30, remoteUrl: url)
                            logger.debug("Prefetched contents of URL \(url) to \(path)")
                        }
                    }
                } catch {
                    logger.warning("Failed to prefetch build artifacts for test arg file entry at index \(index): \(error). This error will be ignored.")
                }
            }
            let dumpOperation = BlockOperation { [logger, runtimeDumpRemoteCacheProvider, testDiscoveryQuerier] in
                do {
                    let configuration = TestDiscoveryConfiguration(
                        analyticsConfiguration: testArgFile.prioritizedJob.analyticsConfiguration,
                        developerDir: testArgFileEntry.developerDir,
                        pluginLocations: testArgFileEntry.pluginLocations,
                        testDiscoveryMode: try TestDiscoveryModeDeterminer.testDiscoveryMode(testArgFileEntry: testArgFileEntry),
                        simulatorOperationTimeouts: testArgFileEntry.simulatorOperationTimeouts,
                        simulatorSettings: testArgFileEntry.simulatorSettings,
                        testDestination: testArgFileEntry.testDestination,
                        testExecutionBehavior: TestExecutionBehavior(
                            environment: testArgFileEntry.environment,
                            numberOfRetries: testArgFileEntry.numberOfRetries
                        ),
                        testRunnerTool: testArgFileEntry.testRunnerTool,
                        testTimeoutConfiguration: testTimeoutConfigurationForRuntimeDump,
                        testsToValidate: testArgFileEntry.testsToRun,
                        xcTestBundleLocation: testArgFileEntry.buildArtifacts.xcTestBundle.location,
                        remoteCache: runtimeDumpRemoteCacheProvider.remoteCache(config: remoteCacheConfig),
                        logger: logger
                    )
                    
                    let result = try testDiscoveryQuerier.query(
                        configuration: configuration
                    ).discoveredTests.tests
                    logger.debug("Test bundle \(testArgFileEntry.buildArtifacts.xcTestBundle) contains \(result.count) tests")
                    discoveredTests.withExclusiveAccess {
                        $0[index] = result
                    }
                } catch {
                    logger.error("Failed to discover tests for test bundle \(testArgFileEntry.buildArtifacts.xcTestBundle): \(error)")
                    collectedErrors.withExclusiveAccess {
                        $0.append(CollectedError.testDiscoveryError(entryIndex: index, error: error))
                    }
                }
            }
            
            dumpOperation.addDependency(downloadOperation)
            
            downloadQueue.addOperation(downloadOperation)
            dumpQueue.addOperation(dumpOperation)
            
            rootOperation.addDependency(downloadOperation)
            rootOperation.addDependency(dumpOperation)
        }
        
        dumpQueue.addOperation(rootOperation)
        rootOperation.waitUntilFinished()
        
        if !collectedErrors.currentValue().isEmpty {
            throw CollectedError.multipleErrors(collectedErrors.currentValue())
        }
        
        return discoveredTests.currentValue()
    }
}

private enum CollectedError: Error, CustomStringConvertible {
    case testDiscoveryError(entryIndex: Int, error: Error)
    case multipleErrors([Error])
    
    var description: String {
        switch self {
        case .testDiscoveryError(let entryIndex, let error):
            return "Error discovering tests in build artifacts of test arg file entry at index \(entryIndex): \(error)"
        case .multipleErrors(let errors):
            if errors.isEmpty {
                return "No errors occured. If you see this message, there's likely a bug in code."
            }
            if errors.count == 1, let singleError = errors.first {
                return "\(singleError)"
            } else {
                return "Multiple errors occured during test discovery: " + errors.map { "\($0)" }.joined(separator: "; ")
            }
        }
    }
}

private extension BuildArtifacts {
    struct BuildArtifactsMisconfiguration: Error, CustomStringConvertible {
        let description = "Missing app bundle"
    }
    
    func requiredArtifacts() throws -> [ResourceLocation] {
        switch xcTestBundle.testDiscoveryMode {
        case .parseFunctionSymbols, .runtimeLogicTest:
            return [xcTestBundle.location.resourceLocation]
        case .runtimeExecutableLaunch, .runtimeAppTest:
            guard let appBundle = appBundle else { throw BuildArtifactsMisconfiguration() }
            return [xcTestBundle.location.resourceLocation, appBundle.resourceLocation]
        }
    }
}
