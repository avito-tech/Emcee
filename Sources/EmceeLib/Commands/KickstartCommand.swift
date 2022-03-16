import ArgLib
import EmceeDI
import EmceeVersion
import Foundation
import EmceeLogging
import QueueClient
import QueueModels
import RequestSender
import SocketModels
import Types

public final class KickstartCommand: Command {
    public let name = "kickstart"
    public let description = "Attempts to restart the Emcee worker"
    public let arguments: Arguments = [
        ArgumentDescriptions.queueServer.asRequired,
        ArgumentDescriptions.workerId.asMultiple.asRequired,
    ]
    
    private let callbackQueue = DispatchQueue(label: "KickstartCommand.callbackQueue")
    private let di: DI
    
    public init(di: DI) throws {
        self.di = di
    }
    
    public func run(payload: CommandPayload) throws {
        let requestSenderProvider: RequestSenderProvider = try di.get()
        let logger: ContextualLogger = try di.get()
        
        let queueServerAddress: SocketAddress = try payload.expectedSingleTypedValue(argumentName: ArgumentDescriptions.queueServer.name)
        let workerIds: [WorkerId] = try payload.nonEmptyCollectionOfValues(argumentName: ArgumentDescriptions.workerId.name)
        
        let kickstarter = WorkerKickstarterImpl(
            requestSender: requestSenderProvider.requestSender(
                socketAddress: queueServerAddress
            )
        )
        
        let waitingGroup = DispatchGroup()
        
        for workerId in workerIds {
            waitingGroup.enter()
            
            logger.info("Attempting to kickstart \(workerId)")
            kickstarter.kickstart(workerId: workerId, callbackQueue: callbackQueue) { [logger] result in
                defer {
                    waitingGroup.leave()
                }
                do {
                    let workerId = try result.dematerialize()
                    logger.info("Successfully kickstarted \(workerId)")
                } catch {
                    logger.error("Failed to kickstart worker \(workerId): \(error)")
                }
            }
        }

        waitingGroup.wait()
    }
}
