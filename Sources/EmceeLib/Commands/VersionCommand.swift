import ArgLib
import EmceeLogging
import EmceeVersion
import Foundation
import QueueModels

public final class VersionCommand: Command {
    public let name = "version"
    public let description = "Returns Emcee version"
    public let arguments: Arguments = [
        ArgumentDescriptions.emceeVersion.asOptional,
    ]
    
    public init() {}

    public func run(payload: CommandPayload) throws {
        let emceeVersion: Version = try payload.optionalSingleTypedValue(argumentName: ArgumentDescriptions.emceeVersion.name) ?? EmceeVersion.version
        
        print(emceeVersion.value)
    }
}
