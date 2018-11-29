import DistRun
import Foundation
import Models
import ModelsTestHelpers
import XCTest

final class ResultsCollectorTests: XCTestCase {
    func test_adding_results() {
        let testingResult1 = TestingResultFixtures()
            .with(testEntry: TestEntry(className: "class1", methodName: "method1", caseId: nil))
            .addingLostResult()
            .testingResult()
        
        let testingResult2 = TestingResultFixtures()
            .with(testEntry: TestEntry(className: "class2", methodName: "method2", caseId: nil))
            .addingLostResult()
            .testingResult()
        
        
        let collector = ResultsCollector()
        collector.append(testingResult: testingResult1)
        collector.append(testingResult: testingResult2)
        
        XCTAssertEqual(collector.collectedResults, [testingResult1, testingResult2])
    }
}

