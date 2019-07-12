import ArgLib
import Foundation

final class CommandA: Command {
    let name: String = "command_a"
    let description: String = ""
    let arguments = Arguments([])
    
    var didRun = false
    
    func run(payload: CommandPayload) throws {
        didRun = true
    }
}

final class CommandB: Command {
    let name: String = "command_b"
    let description: String = ""
    let arguments = Arguments(
        [
            ArgumentDescription(name: .doubleDashed(dashlessName: "string"), overview: "string"),
            ArgumentDescription(name: .doubleDashed(dashlessName: "int"), overview: "int")
        ]
    )
    
    var didRun = false
    
    func run(payload: CommandPayload) throws {
        didRun = true
    }
}
