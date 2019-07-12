import ArgLib
import Foundation
import XCTest

class CommandParserTests: XCTestCase {
    let commandA = CommandA()
    let commandB = CommandB()
    
    lazy var commands: [Command] = [
        commandA,
        commandB
    ]
    
    func test___choosing_command_a() {
        XCTAssertEqual(
            try CommandParser.choose(commandFrom: commands, stringValues: ["command_a"]).name,
            "command_a"
        )
    }
    
    func test___choosing_command_b() {
        XCTAssertEqual(
            try CommandParser.choose(commandFrom: commands, stringValues: ["command_b"]).name,
            "command_b"
        )
    }
    
    func test___choosing_command_from_commandless_input_throws() {
        XCTAssertThrowsError(
            try CommandParser.choose(commandFrom: [], stringValues: [])
        )
    }
    
    func test___choosing_command_from_input_with_unknown_command_throws() {
        XCTAssertThrowsError(
            try CommandParser.choose(commandFrom: [], stringValues: ["unknown"])
        )
    }
    
    func test___mapping_command_argument() throws {
        let valueHolders = try CommandParser.map(
            stringValues: ["--string", "hello", "--int", "42"],
            to: commandB.arguments.argumentDescriptions
        )
        
        let expectedHolders: [ArgumentValueHolder] = [
            ArgumentValueHolder(
                argumentName: commandB.arguments.argumentDescriptions[0].name,
                stringValue: "hello"
            ),
            ArgumentValueHolder(
                argumentName: commandB.arguments.argumentDescriptions[1].name,
                stringValue: "42"
            )
        ]
        
        XCTAssertEqual(valueHolders, Set(expectedHolders))
    }
    
    func test___mapping_command_argument_with_unexpected_argument___throws() {
        XCTAssertThrowsError(
            try CommandParser.map(
                stringValues: ["--string", "hello", "--int", "42", "--unexpected", "arg"],
                to: commandB.arguments.argumentDescriptions
            )
        )
    }
    
    func test___mapping_command_argument_with_missing_argument___throws() {
        XCTAssertThrowsError(
            try CommandParser.map(
                stringValues: ["--string", "hello"],
                to: commandB.arguments.argumentDescriptions
            )
        )
    }
    
    func test___mapping_command_argument_with_missing_argument_value() {
        XCTAssertThrowsError(
            try CommandParser.map(
                stringValues: ["--string", "hello", "--int"],
                to: commandB.arguments.argumentDescriptions
            )
        )
    }
}
