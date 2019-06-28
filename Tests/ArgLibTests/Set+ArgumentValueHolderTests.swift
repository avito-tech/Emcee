import ArgLib
import Foundation
import XCTest

final class Set_ArgumentValueHolderTests: XCTestCase {
    func test___extracting_argument_values() throws {
        let valueHolders = Set(
            [
                ArgumentValueHolder(argumentDescription: StringArgumentDescription(name: "string", overview: ""), stringValue: "hello"),
                ArgumentValueHolder(argumentDescription: IntArgumentDescription(name: "int", overview: ""), stringValue: "42")
            ]
        )
        
        XCTAssertEqual(
            try valueHolders.value(forArgumentWithName: "int"),
            42
        )
        XCTAssertEqual(
            try valueHolders.value(forArgumentWithName: "string"),
            "hello"
        )
    }
    
    func test___throws_on_unexpected_argument_value_request() throws {
        let valueHolders = Set<ArgumentValueHolder>()
        
        XCTAssertThrowsError(
            try valueHolders.value(forArgumentWithName: "argname") as String
        )
    }
}

