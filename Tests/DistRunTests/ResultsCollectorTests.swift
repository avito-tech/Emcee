import DistRun
import Foundation
import Models
import ModelsTestHelpers
import XCTest

final class ResultsCollectorTests: XCTestCase {
    func test_adding_results() {
        let testingResult1 = TestingResultFixtures.createTestingResult(
            unfilteredResults: [TestEntryResult.lost(testEntry: TestEntry(className: "class1", methodName: "method1", caseId: nil))])
        let testingResult2 = TestingResultFixtures.createTestingResult(
            unfilteredResults: [TestEntryResult.lost(testEntry: TestEntry(className: "class2", methodName: "method2", caseId: nil))])
        
        let collector = ResultsCollector()
        collector.append(testingResult: testingResult1)
        collector.append(testingResult: testingResult2)
        
        XCTAssertEqual(collector.collectedResults, [testingResult1, testingResult2])
    }
}

