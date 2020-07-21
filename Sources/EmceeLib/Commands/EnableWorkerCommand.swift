import ArgLib
import AtomicModels
import Foundation
import Logging
import QueueClient
import QueueModels
import RequestSender
import SocketModels
import SynchronousWaiter
import Types

public final class EnableWorkerCommand: Command {
    public let name = "enableWorker"
    
    public let description = "Enables the provided worker: queue will let it execute further jobs"
    
    public var arguments: Arguments = [
        ArgumentDescriptions.queueServer.asRequired,
        ArgumentDescriptions.workerId.asRequired,
    ]
    
    private let callbackQueue = DispatchQueue(label: "EnableWorkerCommand.callbackQueue")
    private let requestSenderProvider: RequestSenderProvider
    
    public init(requestSenderProvider: RequestSenderProvider) {
        self.requestSenderProvider = requestSenderProvider
    }
    
    public func run(payload: CommandPayload) throws {
        let queueServerAddress: SocketAddress = try payload.expectedSingleTypedValue(argumentName: ArgumentDescriptions.queueServer.name)
        let workerId: WorkerId = try payload.expectedSingleTypedValue(argumentName: ArgumentDescriptions.workerId.name)
        
        let workerEnabler = WorkerEnablerImpl(
            requestSender: requestSenderProvider.requestSender(
                socketAddress: queueServerAddress
            )
        )
        
        let enabledWorkerId = AtomicValue<Either<WorkerId, Error>?>(nil)
        
        workerEnabler.enableWorker(
            workerId: workerId,
            callbackQueue: callbackQueue
        ) { (result: Either<WorkerId, Error>) in
            enabledWorkerId.set(result)
        }
        
        let queueResponse = try SynchronousWaiter().waitForUnwrap(
            timeout: 15,
            valueProvider: { enabledWorkerId.currentValue() },
            description: "Performing request to the queue"
        )
        do {
            Logger.always("Successfully enabled worker \(try queueResponse.dematerialize()) on queue \(queueServerAddress)")
        } catch {
            Logger.error("Failed to enable worker \(workerId) on queue \(queueServerAddress): \(error)")
        }
    }
    
    
}
