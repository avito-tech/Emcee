import ArgumentsParser
import DistWorker
import Foundation
import Logging
import ResourceLocationResolver
import Utility

final class DistWorkCommand: Command {
    let command = "distWork"
    let overview = "Takes jobs from a dist runner queue and performs them"
    
    private let queueServer: OptionArgument<String>
    private let workerId: OptionArgument<String>
    private let resourceLocationResolver = ResourceLocationResolver()
    
    required init(parser: ArgumentParser) {
        let subparser = parser.add(subparser: command, overview: overview)
        queueServer = subparser.add(stringArgument: KnownStringArguments.queueServer)
        workerId = subparser.add(stringArgument: KnownStringArguments.workerId)
    }
    
    func run(with arguments: ArgumentParser.Result) throws {
        let queueServerAddress = try ArgumentsReader.socketAddress(arguments.get(self.queueServer), key: KnownStringArguments.queueServer)
        let workerId = try ArgumentsReader.validateNotNil(arguments.get(self.workerId), key: KnownStringArguments.workerId)
        
        let distWorker = DistWorker(
            queueServerAddress: queueServerAddress,
            workerId: workerId,
            resourceLocationResolver: resourceLocationResolver
        )
        try distWorker.start()
    }
}
