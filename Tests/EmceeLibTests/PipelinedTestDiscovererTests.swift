import AtomicModels
import BuildArtifacts
import BuildArtifactsTestHelpers
import EmceeLogging
import EmceeLib
import Foundation
import PathLib
import QueueModels
import SimulatorPoolTestHelpers
import TestArgFile
import TestDiscovery
import TestHelpers
import URLResource
import XCTest

final class PipelinedTestDiscovererTests: XCTestCase {
    private lazy var urlResource = FakeURLResource()
    private lazy var testDiscoveryQuerier = TestDiscoveryQuerierMock()
    private lazy var runtimeDumpRemoteCacheProvider = FakeRuntimeDumpRemoteCacheProvider()
    private lazy var discoverer = PipelinedTestDiscoverer(
        runtimeDumpRemoteCacheProvider: runtimeDumpRemoteCacheProvider,
        testDiscoveryQuerier: testDiscoveryQuerier,
        urlResource: urlResource
    )
    
    func test___empty_results() throws {
        let result = try discoverer.performTestDiscovery(
            logger: .noOp,
            testArgFile: TestArgFile.create(
                buildArtifacts: []
            ),
            remoteCacheConfig: nil
        )
        
        XCTAssertTrue(result.isEmpty)
    }
    
    func test___prefetches_all_required_urls() throws {
        let urls = [
            URL(string: "http://example.com/url1")!,
            URL(string: "http://example.com/url2")!,
        ]
        
        var buildArtifacts = urls.map {
            IosBuildArtifacts.iosLogicTests(
                xcTestBundle: XcTestBundle(
                    location: TestBundleLocation(.remoteUrl($0, [:])),
                    testDiscoveryMode: .parseFunctionSymbols
                )
            )
        }
        
        let appBundleUrl = URL(string: "http://example.com/appBundle")!
        let testBundleUrl = URL(string: "http://example.com/testBundle")!
        
        buildArtifacts.append(
            IosBuildArtifacts.iosApplicationTests(
                xcTestBundle: XcTestBundle(
                    location: TestBundleLocation(.remoteUrl(testBundleUrl, [:])),
                    testDiscoveryMode: .runtimeAppTest
                ),
                appBundle: AppBundleLocation(.remoteUrl(appBundleUrl, [:]))
            )
        )
        
        let fetchedUrls = AtomicValue<[URL]>([])
        urlResource.onFetch = { url in
            fetchedUrls.withExclusiveAccess { $0.append(url) }
        }
        
        _ = try discoverer.performTestDiscovery(
            logger: .noOp,
            testArgFile: TestArgFile.create(
                buildArtifacts: buildArtifacts
            ),
            remoteCacheConfig: nil
        )
        
        XCTAssertEqual(
            Set(fetchedUrls.currentValue()),
            Set(urls + [appBundleUrl, testBundleUrl])
        )
    }
    
    func test___returns_index_based_results() throws {
        let urls = [
            URL(string: "http://example.com/url1")!,
            URL(string: "http://example.com/url2")!,
        ]
        
        let buildArtifacts = urls.map {
            IosBuildArtifacts.iosLogicTests(
                xcTestBundle: XcTestBundle(
                    location: TestBundleLocation(.remoteUrl($0, [:])),
                    testDiscoveryMode: .parseFunctionSymbols
                )
            )
        }
        
        let discoveredTestEntry = DiscoveredTestEntry(className: "class", path: "", testMethods: [], caseId: nil, tags: [])
        testDiscoveryQuerier.resultProvider = { testDiscoveryConfiguration in
            if testDiscoveryConfiguration.xcTestBundleLocation.description.contains("1") {
                return TestDiscoveryResult(
                    discoveredTests: DiscoveredTests(tests: []),
                    unavailableTestsToRun: []
                )
            } else {
                return TestDiscoveryResult(
                    discoveredTests: DiscoveredTests(
                        tests: [
                            discoveredTestEntry,
                        ]
                    ),
                    unavailableTestsToRun: []
                )
            }
        }
        
        let results = try discoverer.performTestDiscovery(
            logger: .noOp,
            testArgFile: TestArgFile.create(
                buildArtifacts: buildArtifacts
            ),
            remoteCacheConfig: nil
        )
        
        XCTAssertEqual(
            results,
            [
                [],
                [discoveredTestEntry],
            ]
        )
    }
}

private class FakeURLResource: URLResource {
    init() {}
    
    func deleteResource(url: URL) throws {}
    func evictResources(olderThan date: Date) throws -> [AbsolutePath] { [] }
    func evictResources(toFitSize bytes: Int) throws -> [AbsolutePath] { [] }
    
    public var onFetch: (URL) -> () = { _ in }
    
    func fetchResource(url: URL, handler: URLResourceHandler, headers: [String: String]?) {
        onFetch(url)
        handler.resource(path: AbsolutePath.root, forUrl: url)
    }
    
    func whileLocked<T>(work: () throws -> (T)) throws -> T {
        try work()
    }
}

private class FakeRuntimeDumpRemoteCacheProvider: RuntimeDumpRemoteCacheProvider {
    func remoteCache(config: RuntimeDumpRemoteCacheConfig?) -> RuntimeDumpRemoteCache {
        NoOpRuntimeDumpRemoteCache()
    }
}

extension TestArgFile {
    static func create(buildArtifacts: [IosBuildArtifacts]) -> TestArgFile {
        TestArgFile(
            entries: buildArtifacts.map {
                TestArgFileEntry(
                    buildArtifacts: $0,
                    developerDir: TestArgFileDefaultValues.developerDir,
                    environment: TestArgFileDefaultValues.environment,
                    userInsertedLibraries: TestArgFileDefaultValues.userInsertedLibraries,
                    numberOfRetries: 0,
                    testRetryMode: .retryOnWorker,
                    logCapturingMode: .noLogs,
                    runnerWasteCleanupPolicy: .clean,
                    pluginLocations: [],
                    scheduleStrategy: TestArgFileDefaultValues.scheduleStrategy,
                    simulatorOperationTimeouts: TestArgFileDefaultValues.simulatorOperationTimeouts,
                    simulatorSettings: TestArgFileDefaultValues.simulatorSettings,
                    testDestination: TestDestinationFixtures.testDestination,
                    testTimeoutConfiguration: TestArgFileDefaultValues.testTimeoutConfiguration,
                    testAttachmentLifetime: TestArgFileDefaultValues.testAttachmentLifetime,
                    testsToRun: [],
                    workerCapabilityRequirements: []
                )
            },
            prioritizedJob: PrioritizedJob(
                analyticsConfiguration: TestArgFileDefaultValues.analyticsConfiguration,
                jobGroupId: "groupId",
                jobGroupPriority: .medium,
                jobId: "jobId",
                jobPriority: .medium
            ),
            testDestinationConfigurations: []
        )
    }
}
