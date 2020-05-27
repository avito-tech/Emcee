import ArgLib
import Logging
import Models
import QueueClient
import RequestSender
import RESTMethods

public final class ToggleWorkersSharingCommand: Command {
    public let name = "toggleWorkersSharing"
    
    public let description = "Changes state of queue workers sharing feature"
    
    public var arguments: Arguments = [
        ArgumentDescriptions.queueServer.asRequired,
        ArgumentDescriptions.setFeatureStatus.asRequired,
    ]
    
    private let requestSenderProvider: RequestSenderProvider
    
    public init(requestSenderProvider: RequestSenderProvider) {
        self.requestSenderProvider = requestSenderProvider
    }
    
    public func run(payload: CommandPayload) throws {
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
            Logger.always("Successfully \(sharingStatus) workers sharing feature on queue \(queueServerAddress)")
        } catch {
            Logger.error("Failed to \(sharingStatus) workers sharing feature on queue \(queueServerAddress): \(error)")
        }
    }
}
