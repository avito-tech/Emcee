import ArgLib
import Foundation

final class CommandA: Command {
    let name = "command_a"
    let description = "command a"
    let arguments = Arguments([])
    
    var didRun = false
    
    func run(payload: CommandPayload) throws {
        didRun = true
    }
}

final class CommandB: Command {
    let name = "command_b"
    let description = "command b"
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

final class CommandC: Command {
    let name = "command_c"
    let description = "command c"
    let arguments: Arguments = [
        ArgumentDescription(name: .doubleDashed(dashlessName: "required"), overview: "required int").asRequired,
        ArgumentDescription(name: .doubleDashed(dashlessName: "optional"), overview: "optional int").asOptional,
    ]
    
    var requiredValue: Int?
    var optionalValue: Int?
    
    func run(payload: CommandPayload) throws {
        requiredValue = try payload.expectedSingleTypedValue(argumentName: .doubleDashed(dashlessName: "required"))
        optionalValue = try payload.optionalSingleTypedValue(argumentName: .doubleDashed(dashlessName: "optional"))
    }
}
