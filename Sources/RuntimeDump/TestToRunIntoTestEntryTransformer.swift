import Foundation
import Models

public final class TestToRunIntoTestEntryTransformer {
    public init() {}
    
    public func transform(
        runtimeQueryResult: RuntimeQueryResult,
        buildArtifacts: BuildArtifacts
    ) throws -> [ValidatedTestEntry] {
        guard runtimeQueryResult.unavailableTestsToRun.isEmpty else {
            throw TransformationError.someTestsAreMissingInRuntime(runtimeQueryResult.unavailableTestsToRun)
        }
        
        let testsToTransform = allExistingTestsFromRuntimeDump(runtimeQueryResult: runtimeQueryResult)
        
        var result = [ValidatedTestEntry]()
        for testName in testsToTransform {
            let matchingRuntimeEntry = runtimeQueryResult.availableRuntimeTests.first { runtimeEntry -> Bool in
                return runtimeEntry.className == testName.className
                    && runtimeEntry.testMethods.contains(testName.methodName)
            }
            if let matchingRuntimeEntry = matchingRuntimeEntry {
                let testEntry = try testEntryFor(testName: testName, runtimeEntry: matchingRuntimeEntry)
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
    
    private func allExistingTestsFromRuntimeDump(runtimeQueryResult: RuntimeQueryResult) -> [TestName] {
        return runtimeQueryResult.availableRuntimeTests.flatMap { runtimeEntry -> [TestName] in
            runtimeEntry.testMethods.map { methodName -> TestName in
                TestName(className: runtimeEntry.className, methodName: methodName)
            }
        }
    }
    
    private func testEntryFor(
        testName: TestName,
        runtimeEntry: RuntimeTestEntry
    ) throws -> TestEntry {
        return TestEntry(
            testName: testName,
            tags: runtimeEntry.tags,
            caseId: runtimeEntry.caseId
        )
    }
}
