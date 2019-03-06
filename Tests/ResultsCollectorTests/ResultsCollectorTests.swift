import Foundation
import Models
import ModelsTestHelpers
import ResultsCollector
import XCTest

final class ResultsCollectorTests: XCTestCase {
    func test_adding_results() {
        let testingResult1 = TestingResultFixtures()
            .with(testEntry: TestEntryFixtures.testEntry(className: "class1", methodName: "method1"))
            .addingLostResult()
            .testingResult()
        
        let testingResult2 = TestingResultFixtures()
            .with(testEntry: TestEntryFixtures.testEntry(className: "class2", methodName: "method2"))
            .addingLostResult()
            .testingResult()
        
        
        let collector = ResultsCollector()
        collector.append(testingResult: testingResult1)
        collector.append(testingResult: testingResult2)
        
        XCTAssertEqual(collector.collectedResults, [testingResult1, testingResult2])
    }
}

