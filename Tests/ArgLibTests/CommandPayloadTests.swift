import ArgLib
import Foundation
import XCTest

final class CommandPayloadTests: XCTestCase {
    func test___extracting_argument_values() throws {
        let valueHolders = Set(
            [
                ArgumentValueHolder(argumentName: .doubleDashed(dashlessName: "string"), stringValue: "hello"),
                ArgumentValueHolder(argumentName: .doubleDashed(dashlessName: "int"), stringValue: "42")
            ]
        )
        let payload = CommandPayload(valueHolders: valueHolders)
        
        XCTAssertEqual(
            try payload.expectedTypedValue(argumentName: .doubleDashed(dashlessName: "int")),
            42
        )
        XCTAssertEqual(
            try payload.expectedTypedValue(argumentName: .doubleDashed(dashlessName: "string")),
            "hello"
        )
    }
    
    func test___throws_on_unexpected_argument_value_request() throws {
        let payload = CommandPayload(valueHolders: Set())
        
        XCTAssertThrowsError(
            try payload.expectedTypedValue(argumentName: .doubleDashed(dashlessName: "argname")) as String
        )
    }
    
    func test___optional_value_holder_returns_nil___when_argument_is_missing() throws {
        let payload = CommandPayload(valueHolders: Set())
        
        XCTAssertNil(
            try payload.optionalTypedValue(argumentName: .doubleDashed(dashlessName: "argname")) as String?
        )
    }
    
    func test___optional_value_holder_throws___when_argument_is_throws() throws {
        let payload = CommandPayload(
            valueHolders: Set(
                [
                    ArgumentValueHolder(argumentName: .doubleDashed(dashlessName: "fake"), stringValue: "hello")
                ]
            )
        )
        
        XCTAssertThrowsError(
            try payload.optionalTypedValue(argumentName: .doubleDashed(dashlessName: "fake")) as FakeArg?
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
