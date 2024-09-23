import AtomicModels
import BuildArtifacts
import CommonTestModels
import EmceeDI
import EmceeLogging
import Foundation
import QueueModels
import ResourceLocation
import TestArgFile
import TestDiscovery
import URLResource

import protocol URLResource.URLResource

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
        remoteCacheConfig: RuntimeDumpRemoteCacheConfig?
    ) throws -> [[DiscoveredTestEntry]] {        
        let discoveredTests = AtomicValue<[[DiscoveredTestEntry]]>(
            Array(repeating: [], count: testArgFile.entries.count)
        )
        let collectedErrors = AtomicValue<[Error]>([])
        
        let rootOperation = BlockOperation { [logger] in
            logger.trace("Finished pipelined test discovery")
        }
        
        testArgFile.entries.enumerated().forEach { index, testArgFileEntry in
            let downloadOperation = BlockOperation { [urlResource, logger] in
                do {
                    let requiredArtifacts = try testArgFileEntry.buildArtifacts.requiredArtifacts()
                    for artifact in requiredArtifacts {
                        if let url = artifact.url {
                            let handler = BlockingURLResourceHandler()
                            urlResource.fetchResource(url: url, handler: handler, headers: artifact.headers)
                            let path = try handler.wait(limit: 30, remoteUrl: url)
                            logger.trace("Prefetched contents of URL \(url) to \(path)")
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
                        logger: logger,
                        remoteCache: runtimeDumpRemoteCacheProvider.remoteCache(config: remoteCacheConfig),
                        testsToValidate: testArgFileEntry.testsToRun,
                        testDiscoveryMode: try TestDiscoveryModeDeterminer.testDiscoveryMode(
                            testArgFileEntry: testArgFileEntry
                        ),
                        testConfiguration: try testArgFileEntry.appleTestConfiguration()
                    )
                    
                    let result = try testDiscoveryQuerier.query(
                        configuration: configuration
                    ).discoveredTests.tests
                    logger.trace("Test bundle \(testArgFileEntry.buildArtifacts.xcTestBundle) contains \(result.count) tests")
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

private extension AppleBuildArtifacts {
    struct BuildArtifactsMisconfiguration: Error, CustomStringConvertible {
        let description = "Test discovery requires app bundle to be present but it is missing in build artifacts"
    }
    
    func requiredArtifacts() throws -> [ResourceLocation] {
        switch self {
        case .iosLogicTests(let xcTestBundle):
            switch xcTestBundle.testDiscoveryMode {
            case .parseFunctionSymbols, .runtimeLogicTest:
                return [xcTestBundle.location.resourceLocation]
            case .runtimeExecutableLaunch, .runtimeAppTest:
                throw BuildArtifactsMisconfiguration()
            }
            
        case .iosApplicationTests(let xcTestBundle, let appBundle):
            switch xcTestBundle.testDiscoveryMode {
            case .parseFunctionSymbols, .runtimeLogicTest:
                return [xcTestBundle.location.resourceLocation]
            case .runtimeExecutableLaunch, .runtimeAppTest:
                return [xcTestBundle.location.resourceLocation, appBundle.resourceLocation]
            }
            
        case .iosUiTests(let xcTestBundle, let appBundle, _, _):
            switch xcTestBundle.testDiscoveryMode {
            case .parseFunctionSymbols, .runtimeLogicTest:
                return [xcTestBundle.location.resourceLocation]
            case .runtimeExecutableLaunch, .runtimeAppTest:
                return [xcTestBundle.location.resourceLocation, appBundle.resourceLocation]
            }
        }
    }
}
