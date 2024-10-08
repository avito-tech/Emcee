import CommonTestModels
import Foundation
import TestArgFile
import XCTest

final class TestToRunTests: XCTestCase {
    let decoder = JSONDecoder()
    
    func test__parsing_single_test_name() {
        let json = "{\"test\": {\"predicateType\": \"singleTestName\", \"testName\": \"ClassName/testName\"}}"
        
        let expected = ["test": TestToRun.testName(TestName(className: "ClassName", methodName: "testName"))]
        
        XCTAssertEqual(
            try decoder.decode([String: TestToRun].self, from: Data(json.utf8)),
            expected
        )
    }
    
    func test__parsing_all_tests_provided_by_runtime_dump() {
        let json = "{\"test\": {\"predicateType\": \"allDiscoveredTests\"}}"
        
        let expected = ["test": TestToRun.allDiscoveredTests]
        
        XCTAssertEqual(
            try decoder.decode([String: TestToRun].self, from: Data(json.utf8)),
            expected
        )
    }
}

