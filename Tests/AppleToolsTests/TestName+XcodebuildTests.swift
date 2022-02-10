import AppleTools
import CommonTestModels
import Foundation
import TestHelpers
import XCTest

final class TestName_XcodebuildTests: XCTestCase {
    func test___parsing_valid_string___with_module_and_class_name() throws {
        let testName = assertDoesNotThrow {
            try TestName.parseObjCTestName(string: "-[ModuleWithTests.TestClassName testMethodName]")
        }
        
        XCTAssertEqual(
            testName,
            TestName(className: "TestClassName", methodName: "testMethodName")
        )
    }
    
    func test___parsing_valid_string___without_module_name() throws {
        let testName = assertDoesNotThrow {
            try TestName.parseObjCTestName(string: "-[TestClassName testMethodName]")
        }
        
        XCTAssertEqual(
            testName,
            TestName(className: "TestClassName", methodName: "testMethodName")
        )
    }
    
    func test___parsing_invalid_string() throws {
        assertThrows { try TestName.parseObjCTestName(string: "-[TestClassName_testMethodName]") }
        assertThrows { try TestName.parseObjCTestName(string: "TestClassName testMethodName") }
        assertThrows { try TestName.parseObjCTestName(string: "-[ModuleName. testMethodName]") }
        assertThrows { try TestName.parseObjCTestName(string: "-[.TestClassName testMethodName]") }
        assertThrows { try TestName.parseObjCTestName(string: "-[]") }
        assertThrows { try TestName.parseObjCTestName(string: "-[A.B.C test]") }
    }
}
