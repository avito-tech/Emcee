import Foundation
import Models
import XCTest

final class TestToRunTests: XCTestCase {
    let decoder = JSONDecoder()
    
    func test__parsing_old_style() {
        let json = "{\"test\": \"ClassName/testName\"}"
        
        let expected = ["test": TestToRun.testName(TestName(className: "ClassName", methodName: "testName"))]
        
        XCTAssertEqual(
            try decoder.decode([String: TestToRun].self, from: data(json)),
            expected
        )
    }
    
    func test__parsing_single_test_name() {
        let json = "{\"test\": {\"predicateType\": \"singleTestName\", \"testName\": \"ClassName/testName\"}}"
        
        let expected = ["test": TestToRun.testName(TestName(className: "ClassName", methodName: "testName"))]
        
        XCTAssertEqual(
            try decoder.decode([String: TestToRun].self, from: data(json)),
            expected
        )
    }
    
    func test__parsing_all_tests_provided_by_runtime_dump() {
        let json = "{\"test\": {\"predicateType\": \"allProvidedByRuntimeDump\"}}"
        
        let expected = ["test": TestToRun.allProvidedByRuntimeDump]
        
        XCTAssertEqual(
            try decoder.decode([String: TestToRun].self, from: data(json)),
            expected
        )
    }
    
    func data(_ string: String) -> Data {
        return string.data(using: .utf8)!
    }
}

