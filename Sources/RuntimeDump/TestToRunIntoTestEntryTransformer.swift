import Foundation
import Models

public final class TestToRunIntoTestEntryTransformer {
    private let configuration: RuntimeDumpConfiguration
    private let fetchAllTestsIfTestsToRunIsEmpty: Bool
    
    public enum ValidationError: Error, CustomStringConvertible {
        case someTestsAreMissingInRuntime([TestToRun])
        case noMatchFor(TestToRun)
        case unableToExctractClassAndMethodNames(testName: String)
        
        public var description: String {
            switch self {
            case .someTestsAreMissingInRuntime(let testsToRun):
                return "Error: some tests are missing in runtime: \(testsToRun)"
            case .noMatchFor(let testToRun):
                return "Unexpected error: Unable to find expected runtime test match for \(testToRun)"
            case .unableToExctractClassAndMethodNames(let testName):
                return "Error: \(testName) is a wrong test name. Unable to extract class or method."
            }
        }
    }
    
    public init(configuration: RuntimeDumpConfiguration, fetchAllTestsIfTestsToRunIsEmpty: Bool = true) {
        self.configuration = configuration
        self.fetchAllTestsIfTestsToRunIsEmpty = fetchAllTestsIfTestsToRunIsEmpty
    }
    
    public func transform() throws -> [TestEntry] {
        let runtimeQueryResult = try RuntimeTestQuerier(configuration: configuration).queryRuntime()
        guard runtimeQueryResult.unavailableTestsToRun.isEmpty else {
            throw ValidationError.someTestsAreMissingInRuntime(runtimeQueryResult.unavailableTestsToRun)
        }
        
        if configuration.testsToRun.isEmpty && fetchAllTestsIfTestsToRunIsEmpty {
            return runtimeQueryResult.availableRuntimeTests.flatMap { runtimeEntry -> [TestEntry] in
                runtimeEntry.testMethods.map { TestEntry(className: runtimeEntry.className, methodName: $0, caseId: runtimeEntry.caseId) }
            }
        } else if configuration.testsToRun.isEmpty && !fetchAllTestsIfTestsToRunIsEmpty {
            return []
        }
        
        return try configuration.testsToRun.flatMap { testToRun -> [TestEntry] in
            let matchingRuntimeEntry = try runtimeQueryResult.availableRuntimeTests.first { runtimeEntry -> Bool in
                switch testToRun {
                case .testName(let testName):
                    let specifierComponents = try testSpecifierComponentsForTestName(testName: testName)
                    return runtimeEntry.className == specifierComponents.className &&
                        runtimeEntry.testMethods.contains(specifierComponents.methodName)
                case .caseId(let caseId):
                    return runtimeEntry.caseId == caseId
                }
            }
            if let matchingRuntimeEntry = matchingRuntimeEntry {
                return try testEntriesFor(testToRun: testToRun, runtimeEntry: matchingRuntimeEntry)
            } else {
                throw ValidationError.noMatchFor(testToRun)
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
                    caseId: runtimeEntry.caseId)
            ]
        case .caseId:
            return runtimeEntry.testMethods.map {
                TestEntry(
                    className: runtimeEntry.className,
                    methodName: $0,
                    caseId: runtimeEntry.caseId)
            }
        }
    }
    
    private func testSpecifierComponentsForTestName(testName: String) throws -> (className: String, methodName: String) {
        let components = testName.components(separatedBy: "/")
        guard components.count == 2, let className = components.first, let methodName = components.last else {
            throw ValidationError.unableToExctractClassAndMethodNames(testName: testName)
        }
        return (className: className, methodName: methodName)
    }
}
