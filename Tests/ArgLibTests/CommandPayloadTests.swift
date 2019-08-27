import ArgLib
import Foundation
import XCTest

final class CommandPayloadTests: XCTestCase {
    func test___extracting_argument_values() throws {
        let valueHolders = [
            ArgumentValueHolder(argumentName: .doubleDashed(dashlessName: "string"), stringValue: "hello"),
            ArgumentValueHolder(argumentName: .doubleDashed(dashlessName: "int"), stringValue: "42")
        ]
        let payload = CommandPayload(valueHolders: valueHolders)
        
        XCTAssertEqual(
            try payload.expectedSingleTypedValue(argumentName: .doubleDashed(dashlessName: "int")),
            42
        )
        XCTAssertEqual(
            try payload.expectedSingleTypedValue(argumentName: .doubleDashed(dashlessName: "string")),
            "hello"
        )
    }
    
    func test___throws_on_unexpected_argument_value_request() throws {
        let payload = CommandPayload(valueHolders: [])
        
        XCTAssertThrowsError(
            try payload.expectedSingleTypedValue(argumentName: .doubleDashed(dashlessName: "argname")) as String
        )
    }
    
    func test___optional_value_holder_returns_nil___when_argument_is_missing() throws {
        let payload = CommandPayload(valueHolders: [])
        
        XCTAssertNil(
            try payload.optionalSingleTypedValue(argumentName: .doubleDashed(dashlessName: "argname")) as String?
        )
    }
    
    func test___optional_value_holder_throws___when_argument_is_throws() throws {
        let payload = CommandPayload(
            valueHolders: [
                ArgumentValueHolder(argumentName: .doubleDashed(dashlessName: "fake"), stringValue: "hello")
            ]
        )
        
        XCTAssertThrowsError(
            try payload.optionalSingleTypedValue(argumentName: .doubleDashed(dashlessName: "fake")) as FakeArg?
        )
    }
    
    func test___extracting_argument_value_for_optional_argument() throws {
        let valueHolders = [
            ArgumentValueHolder(argumentName: .doubleDashed(dashlessName: "string"), stringValue: "hello")
        ]
        let payload = CommandPayload(valueHolders: valueHolders)

        XCTAssertEqual(
            try payload.optionalSingleTypedValue(argumentName: .doubleDashed(dashlessName: "string")),
            "hello"
        )
    }
    
    func test___empty_collection_of_values() {
        let payload = CommandPayload(valueHolders: [])
        XCTAssertEqual(
            try payload.possiblyEmptyCollectionOfValues(argumentName: .doubleDashed(dashlessName: "arg")) as [String],
            []
        )
    }
    
    func test___single_value_throws___when_multiple_values_present() {
        let payload = CommandPayload(
            valueHolders: [
                ArgumentValueHolder(argumentName: .doubleDashed(dashlessName: "arg"), stringValue: "value1"),
                ArgumentValueHolder(argumentName: .doubleDashed(dashlessName: "arg"), stringValue: "value2")
            ]
        )
        XCTAssertThrowsError(
            try payload.expectedSingleTypedValue(argumentName: .doubleDashed(dashlessName: "arg")) as String
        )
    }
    
    func test___possibly_empty_collection_of_values() {
        let payload = CommandPayload(
            valueHolders: [
                ArgumentValueHolder(argumentName: .doubleDashed(dashlessName: "arg"), stringValue: "value1"),
                ArgumentValueHolder(argumentName: .doubleDashed(dashlessName: "arg"), stringValue: "value2")
            ]
        )
        XCTAssertEqual(
            try payload.possiblyEmptyCollectionOfValues(argumentName: .doubleDashed(dashlessName: "arg")) as [String],
            ["value1", "value2"]
        )
    }
    
    func test___nonempty_collection_of_values___throws_when_no_args_provided() {
        let payload = CommandPayload(valueHolders: [])
        XCTAssertThrowsError(
            try payload.nonEmptyCollectionOfValues(argumentName: .doubleDashed(dashlessName: "arg")) as [String]
        )
    }
    
    func test___nonempty_collection_of_values() {
        let payload = CommandPayload(
            valueHolders: [
                ArgumentValueHolder(argumentName: .doubleDashed(dashlessName: "arg"), stringValue: "value1"),
                ArgumentValueHolder(argumentName: .doubleDashed(dashlessName: "arg"), stringValue: "value2")
            ]
        )
        XCTAssertEqual(
            try payload.nonEmptyCollectionOfValues(argumentName: .doubleDashed(dashlessName: "arg")) as [String],
            ["value1", "value2"]
        )
    }
}

private struct FakeArg: ParsableArgument {
    private enum FakeError: Error {
        case error
    }
    
    init(argumentValue: String) throws {
        throw FakeError.error
    }
}
