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
    
    func test___mapping_command_argument() throws {
        let valueHolders = try CommandParser.map(
            stringValues: ["--string", "hello", "--int", "42"],
            to: commandB.arguments.argumentDescriptions
        )
        
        let expectedHolders: [ArgumentValueHolder] = [
            ArgumentValueHolder(
                argumentDescription: commandB.arguments.argumentDescriptions[0],
                stringValue: "hello"
            ),
            ArgumentValueHolder(
                argumentDescription: commandB.arguments.argumentDescriptions[1],
                stringValue: "42"
            )
        ]
        
        XCTAssertEqual(valueHolders, Set(expectedHolders))
    }
    
    func test___mapping_command_argument_with_unexpected_argument() throws {
        XCTAssertThrowsError(
            try CommandParser.map(
                stringValues: ["--string", "hello", "--int", "42", "--unexpected", "arg"],
                to: commandB.arguments.argumentDescriptions
            )
        )
    }
    
    func test___mapping_command_argument_with_missing_argument() throws {
        XCTAssertThrowsError(
            try CommandParser.map(
                stringValues: ["--string", "hello"],
                to: commandB.arguments.argumentDescriptions
            )
        )
    }
}
