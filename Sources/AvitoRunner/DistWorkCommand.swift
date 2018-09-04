import Foundation
import ArgumentsParser
import DistWork
import Utility
import Logging

final class DistWorkCommand: Command {
    let command = "distWork"
    let overview = "Takes jobs from a dist runner queue and performs them"
    
    enum DistWorkArgumentError: Error, CustomStringConvertible {
        case incorrectFormat
        
        var description: String {
            switch self {
            case .incorrectFormat:
                return "Argument value has incorrect format or unexpected"
            }
        }
    }
    
    private let queueServer: OptionArgument<String>
    private let workerId: OptionArgument<String>
    
    required init(parser: ArgumentParser) {
        let subparser = parser.add(subparser: command, overview: overview)
        queueServer = subparser.add(stringArgument: KnownStringArguments.queueServer)
        workerId = subparser.add(stringArgument: KnownStringArguments.workerId)
    }
    
    func run(with arguments: ArgumentParser.Result) throws {
        guard let queueServer = arguments.get(queueServer) else {
            throw ArgumentsError.argumentIsMissing(KnownStringArguments.queueServer)
        }
        guard let workerId = arguments.get(workerId) else {
            throw ArgumentsError.argumentIsMissing(KnownStringArguments.workerId)
        }
        let components = queueServer.components(separatedBy: ":")
        guard components.count == 2, let serverAddress = components.first, let serverPort = Int(components[1]) else {
            throw ArgumentsError.argumentValueCannotBeUsed(
                KnownStringArguments.queueServer,
                DistWorkArgumentError.incorrectFormat)
        }
        
        let distWorker = DistWorker(queueServerAddress: serverAddress, queueServerPort: serverPort, workerId: workerId)
        try distWorker.start()
    }
}
