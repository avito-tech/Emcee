import ArgLib
import Foundation
import XCTest

final class CommandInvokerTests: XCTestCase {
    func test() throws {
        let commandA = CommandA()
        let commandB = CommandB()
        let invoker = CommandInvoker(
            commands: [commandA, commandB]
        )
        
        try invoker.invokeSuitableCommand(
            arguments: ["command_b", "--string", "str", "--int", "42"]
        )
        
        XCTAssertTrue(commandB.didRun)
        XCTAssertFalse(commandA.didRun)
    }
}

