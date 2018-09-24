import Foundation
import ArgumentsParser
import DistWork
import Utility
import Logging

final class DistWorkCommand: Command {
    let command = "distWork"
    let overview = "Takes jobs from a dist runner queue and performs them"
    
    private let queueServer: OptionArgument<String>
    private let workerId: OptionArgument<String>
    
    required init(parser: ArgumentParser) {
        let subparser = parser.add(subparser: command, overview: overview)
        queueServer = subparser.add(stringArgument: KnownStringArguments.queueServer)
        workerId = subparser.add(stringArgument: KnownStringArguments.workerId)
    }
    
    func run(with arguments: ArgumentParser.Result) throws {
        let queueServer = try ArgumentsReader.queueServer(arguments.get(self.queueServer), key: KnownStringArguments.queueServer)
        let workerId = try ArgumentsReader.validateNotNil(arguments.get(self.workerId), key: KnownStringArguments.workerId)
        
        let distWorker = DistWorker(queueServerAddress: queueServer.host, queueServerPort: queueServer.port, workerId: workerId)
        try distWorker.start()
    }
}
