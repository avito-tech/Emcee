import ArgLib
import Foundation
import XCTest

final class CommandInvokerTests: XCTestCase {
    func test() throws {
        let commandA = CommandA()
        let commandB = CommandB()
        let invoker = CommandInvoker(
            commands: [commandA, commandB],
            helpCommandType: .missing
        )
        
        try invoker.invokeSuitableCommand(
            arguments: ["command_b", "--string", "str", "--int", "42"]
        )
        
        XCTAssertTrue(commandB.didRun)
        XCTAssertFalse(commandA.didRun)
    }
    
    func test_with_all_arguments() throws {
        let command = CommandC()
        let invoker = CommandInvoker(commands: [command], helpCommandType: .missing)
        
        try invoker.invokeSuitableCommand(arguments: ["command_c", "--required", "42", "--optional", "60"])
        
        XCTAssertEqual(command.requiredValue, 42)
        XCTAssertEqual(command.optionalValue, 60)
    }
    
    func test_without_optioanl_arguments() throws {
        let command = CommandC()
        let invoker = CommandInvoker(commands: [command], helpCommandType: .missing)
        
        try invoker.invokeSuitableCommand(arguments: ["command_c", "--required", "42"])
        
        XCTAssertEqual(command.requiredValue, 42)
        XCTAssertNil(command.optionalValue)
    }
}
