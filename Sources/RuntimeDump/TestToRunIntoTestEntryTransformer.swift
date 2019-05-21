import Foundation
import Models

public final class TestToRunIntoTestEntryTransformer {
    private let testsToRun: [TestToRun]
    
    public init(testsToRun: [TestToRun]) {
        self.testsToRun = testsToRun
    }
    
    public func transform(runtimeQueryResult: RuntimeQueryResult) throws -> [TestToRun: [TestEntry]] {
        guard runtimeQueryResult.unavailableTestsToRun.isEmpty else {
            throw TransformationError.someTestsAreMissingInRuntime(runtimeQueryResult.unavailableTestsToRun)
        }
        
        let testsToTransform = allExistingTestsToRunFromRuntimeDump(runtimeQueryResult: runtimeQueryResult)
        
        var result = [TestToRun: [TestEntry]]()
        for testToRun in testsToTransform {
            let matchingRuntimeEntry = try runtimeQueryResult.availableRuntimeTests.first { runtimeEntry -> Bool in
                switch testToRun {
                case .testName(let testName):
                    let specifierComponents = try testSpecifierComponentsForTestName(testName: testName)
                    return runtimeEntry.className == specifierComponents.className &&
                        runtimeEntry.testMethods.contains(specifierComponents.methodName)
                }
            }
            if let matchingRuntimeEntry = matchingRuntimeEntry {
                let testEntries = try testEntriesFor(testToRun: testToRun, runtimeEntry: matchingRuntimeEntry)
                result[testToRun] = testEntries
            } else {
                throw TransformationError.noMatchFor(testToRun)
            }
        }
        return result
    }
    
    private func allExistingTestsToRunFromRuntimeDump(runtimeQueryResult: RuntimeQueryResult) -> [TestToRun] {
        return runtimeQueryResult.availableRuntimeTests.flatMap { runtimeEntry -> [TestToRun] in
            runtimeEntry.testMethods.map { methodName -> TestToRun in
                TestToRun.testName(runtimeEntry.className + "/" + methodName)
            }
        }
    }
    
    private func testEntriesFor(testToRun: TestToRun, runtimeEntry: RuntimeTestEntry) throws -> [TestEntry] {
        switch testToRun {
        case .testName(let testName):
            let specifierComponents = try testSpecifierComponentsForTestName(testName: testName)
            return [
                TestEntry(
                    className: runtimeEntry.className,
                    methodName: specifierComponents.methodName,
                    tags: runtimeEntry.tags,
                    caseId: runtimeEntry.caseId
                )
            ]
        }
    }
    
    private func testSpecifierComponentsForTestName(testName: String) throws -> (className: String, methodName: String) {
        let components = testName.components(separatedBy: "/")
        guard components.count == 2, let className = components.first, let methodName = components.last else {
            throw TransformationError.unableToExctractClassAndMethodNames(testName: testName)
        }
        return (className: className, methodName: methodName)
    }
}
