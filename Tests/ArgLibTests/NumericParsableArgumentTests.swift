import ArgLib
import Foundation
import XCTest

final class NumericParsableArgumentTests: XCTestCase {
    func test__parsing_int() {
        XCTAssertEqual(
            try Int(argumentValue: "10"),
            10
        )
    }
    
    func test__parsing_incorrect_int_throws() {
        XCTAssertThrowsError(
            try Int(argumentValue: "oops")
        )
    }
    
    func test__parsing_uint() {
        XCTAssertEqual(
            try UInt(argumentValue: "10"),
            10
        )
    }
    
    func test__parsing_incorrect_uint_throws() {
        XCTAssertThrowsError(
            try UInt(argumentValue: "oops")
        )
    }
    
    func test___number_parse_error_description_contains_type() {
        XCTAssertEqual(
            NumberParseError<Int>(argumentValue: "string").description,
            "Unable to convert 'string' into Int type"
        )
    }
}

