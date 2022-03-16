import ArgLib
import EmceeDI
import EmceeLogging
import QueueClient
import RESTMethods
import RequestSender
import SocketModels

public final class ToggleWorkersSharingCommand: Command {
    public let name = "toggleWorkersSharing"
    
    public let description = "Changes state of queue workers sharing feature"
    
    public var arguments: Arguments = [
        ArgumentDescriptions.queueServer.asRequired,
        ArgumentDescriptions.setFeatureStatus.asRequired,
    ]
    
    private let di: DI
    
    public init(di: DI) throws {
        self.di = di
    }
    
    public func run(payload: CommandPayload) throws {
        let requestSenderProvider: RequestSenderProvider = try di.get()
        let logger: ContextualLogger = try di.get()
        
        let queueServerAddress: SocketAddress = try payload.expectedSingleTypedValue(argumentName: ArgumentDescriptions.queueServer.name)
        let sharingEnabled: Bool = try payload.expectedSingleTypedValue(argumentName: ArgumentDescriptions.setFeatureStatus.name)
        
        let toggler = DefaultWorkersSharingToggler(
            timeout: 15,
            requestSender: requestSenderProvider.requestSender(
                socketAddress: queueServerAddress
            )
        )
        
        let sharingStatus: WorkersSharingFeatureStatus = sharingEnabled ? .enabled : .disabled
        do {
            try toggler.setSharingStatus(sharingStatus)
            logger.info("Successfully \(sharingStatus) workers sharing feature on queue \(queueServerAddress)")
        } catch {
            logger.error("Failed to \(sharingStatus) workers sharing feature on queue \(queueServerAddress): \(error)")
        }
    }
}
