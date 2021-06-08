import AtomicModels
import BuildArtifacts
import BuildArtifactsTestHelpers
import EmceeLogging
import EmceeLib
import Foundation
import LoggingSetup
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
            emceeVersion: "version",
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
            BuildArtifactsFixtures.with(
                xcTestBundle: XcTestBundle(
                    location: TestBundleLocation(.remoteUrl($0)),
                    testDiscoveryMode: .parseFunctionSymbols
                )
            )
        }
        
        let appBundleUrl = URL(string: "http://example.com/appBundle")!
        let testBundleUrl = URL(string: "http://example.com/testBundle")!
        
        buildArtifacts.append(
            BuildArtifactsFixtures.with(
                appBundle: .remoteUrl(appBundleUrl),
                xcTestBundle: XcTestBundle(
                    location: TestBundleLocation(.remoteUrl(testBundleUrl)),
                    testDiscoveryMode: .runtimeAppTest
                )
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
            emceeVersion: "version",
            remoteCacheConfig: nil
        )
        
        XCTAssertEqual(
            Set(fetchedUrls.currentValue()),
            Set(urls + [appBundleUrl, testBundleUrl])
        )
    }
    
    func test___throws_error___when_required_artifact_is_missing() throws {
        let testBundleUrl = URL(string: "http://example.com/testBundle")!
        
        let buildArtifacts = BuildArtifactsFixtures.with(
            appBundle: nil,                           // app bundle is nil
            xcTestBundle: XcTestBundle(
                location: TestBundleLocation(.remoteUrl(testBundleUrl)),
                testDiscoveryMode: .runtimeAppTest    // requires app bundle, but it is nil
            )
        )

        assertThrows {
            _ = try discoverer.performTestDiscovery(
                logger: .noOp,
                testArgFile: TestArgFile.create(buildArtifacts: [buildArtifacts]),
                emceeVersion: "version",
                remoteCacheConfig: nil
            )
        }
    }
    
    func test___returns_index_based_results() throws {
        let urls = [
            URL(string: "http://example.com/url1")!,
            URL(string: "http://example.com/url2")!,
        ]
        
        let buildArtifacts = urls.map {
            BuildArtifactsFixtures.with(
                xcTestBundle: XcTestBundle(
                    location: TestBundleLocation(.remoteUrl($0)),
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
            emceeVersion: "version",
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
    
    func fetchResource(url: URL, handler: URLResourceHandler, tokens: [String: String]) {
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
    static func create(buildArtifacts: [BuildArtifacts]) -> TestArgFile {
        TestArgFile(
            entries: buildArtifacts.map {
                TestArgFileEntry(
                    buildArtifacts: $0,
                    developerDir: TestArgFileDefaultValues.developerDir,
                    environment: TestArgFileDefaultValues.environment,
                    numberOfRetries: 0,
                    pluginLocations: [],
                    scheduleStrategy: TestArgFileDefaultValues.scheduleStrategy,
                    simulatorControlTool: TestArgFileDefaultValues.simulatorControlTool,
                    simulatorOperationTimeouts: TestArgFileDefaultValues.simulatorOperationTimeouts,
                    simulatorSettings: TestArgFileDefaultValues.simulatorSettings,
                    testDestination: TestDestinationFixtures.testDestination,
                    testRunnerTool: TestArgFileDefaultValues.testRunnerTool,
                    testTimeoutConfiguration: TestArgFileDefaultValues.testTimeoutConfiguration,
                    testType: .appTest,
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
