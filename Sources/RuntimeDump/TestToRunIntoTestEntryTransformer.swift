import Foundation
import Models

public final class TestToRunIntoTestEntryTransformer {
    private let testsToRun: [TestToRun]
    
    public init(testsToRun: [TestToRun]) {
        self.testsToRun = testsToRun
    }
    
    public func transform(
        runtimeQueryResult: RuntimeQueryResult,
        buildArtifacts: BuildArtifacts
    ) throws -> [ValidatedTestEntry] {
        guard runtimeQueryResult.unavailableTestsToRun.isEmpty else {
            throw TransformationError.someTestsAreMissingInRuntime(runtimeQueryResult.unavailableTestsToRun)
        }
        
        let testsToTransform = allExistingTestsToRunFromRuntimeDump(runtimeQueryResult: runtimeQueryResult)
        
        var result = [ValidatedTestEntry]()
        for testToRun in testsToTransform {
            let matchingRuntimeEntry = runtimeQueryResult.availableRuntimeTests.first { runtimeEntry -> Bool in
                switch testToRun {
                case .testName(let testName):
                    return runtimeEntry.className == testName.className
                        && runtimeEntry.testMethods.contains(testName.methodName)
                }
            }
            if let matchingRuntimeEntry = matchingRuntimeEntry {
                let testEntries = try testEntriesFor(testToRun: testToRun, runtimeEntry: matchingRuntimeEntry)
                result.append(
                    ValidatedTestEntry(
                        testToRun: testToRun,
                        testEntries: testEntries,
                        buildArtifacts: buildArtifacts
                    )
                )
            } else {
                throw TransformationError.noMatchFor(testToRun)
            }
        }
        return result
    }
    
    private func allExistingTestsToRunFromRuntimeDump(runtimeQueryResult: RuntimeQueryResult) -> [TestToRun] {
        return runtimeQueryResult.availableRuntimeTests.flatMap { runtimeEntry -> [TestToRun] in
            runtimeEntry.testMethods.map { methodName -> TestToRun in
                TestToRun.testName(
                    TestName(className: runtimeEntry.className, methodName: methodName)
                )
            }
        }
    }
    
    private func testEntriesFor(testToRun: TestToRun, runtimeEntry: RuntimeTestEntry) throws -> [TestEntry] {
        switch testToRun {
        case .testName(let testName):
            return [
                TestEntry(
                    testName: TestName(
                        className: runtimeEntry.className,
                        methodName: testName.methodName
                    ),
                    tags: runtimeEntry.tags,
                    caseId: runtimeEntry.caseId
                )
            ]
        }
    }
}
