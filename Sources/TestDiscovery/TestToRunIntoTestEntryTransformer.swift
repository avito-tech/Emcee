import BuildArtifacts
import Foundation
import RunnerModels

public final class TestToRunIntoTestEntryTransformer {
    public init() {}
    
    public func transform(
        buildArtifacts: IosBuildArtifacts,
        testDiscoveryResult: TestDiscoveryResult
    ) throws -> [ValidatedTestEntry] {
        guard testDiscoveryResult.unavailableTestsToRun.isEmpty else {
            throw TransformationError.someTestsAreMissingInRuntime(testDiscoveryResult.unavailableTestsToRun)
        }
        
        let testsToTransform = allExistingTestsFromDiscoveryResult(testDiscoveryResult: testDiscoveryResult)
        
        var result = [ValidatedTestEntry]()
        for testName in testsToTransform {
            let matchingDiscoveredTestEntry = testDiscoveryResult.discoveredTests.tests.first { discoveredTestEntry -> Bool in
                return discoveredTestEntry.className == testName.className
                    && discoveredTestEntry.testMethods.contains(testName.methodName)
            }
            if let matchingDiscoveredTestEntry = matchingDiscoveredTestEntry {
                let testEntry = try testEntryFor(discoveredTestEntry: matchingDiscoveredTestEntry, testName: testName)
                result.append(
                    ValidatedTestEntry(
                        testName: testName,
                        testEntries: [testEntry],
                        buildArtifacts: buildArtifacts
                    )
                )
            } else {
                throw TransformationError.noMatchFor(testName)
            }
        }
        return result
    }
    
    private func allExistingTestsFromDiscoveryResult(testDiscoveryResult: TestDiscoveryResult) -> [TestName] {
        return testDiscoveryResult.discoveredTests.tests.flatMap { runtimeEntry -> [TestName] in
            runtimeEntry.testMethods.map { methodName -> TestName in
                TestName(className: runtimeEntry.className, methodName: methodName)
            }
        }
    }
    
    private func testEntryFor(
        discoveredTestEntry: DiscoveredTestEntry,
        testName: TestName
    ) throws -> TestEntry {
        return TestEntry(
            testName: testName,
            tags: discoveredTestEntry.tags,
            caseId: discoveredTestEntry.caseId
        )
    }
}
