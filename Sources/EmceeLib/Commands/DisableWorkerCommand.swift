import ArgLib
import AtomicModels
import Foundation
import Logging
import Models
import QueueClient
import RequestSender
import SynchronousWaiter

public final class DisableWorkerCommand: Command {
    public let name = "disableWorker"
    
    public let description = "Disables the provided worker: queue won't let it execute further jobs"
    
    public var arguments: Arguments = [
        ArgumentDescriptions.queueServer.asRequired,
        ArgumentDescriptions.workerId.asRequired,
    ]
    
    private let callbackQueue = DispatchQueue(label: "DisableWorkerCommand.callbackQueue")
    
    public init() {}
    
    public func run(payload: CommandPayload) throws {
        let queueServerAddress: SocketAddress = try payload.expectedSingleTypedValue(argumentName: ArgumentDescriptions.queueServer.name)
        let workerId: WorkerId = try payload.expectedSingleTypedValue(argumentName: ArgumentDescriptions.workerId.name)
        
        let workerDisabler = WorkerDisablerImpl(
            requestSender: RequestSenderImpl(
                urlSession: URLSession.shared,
                queueServerAddress: queueServerAddress
            )
        )
        
        let disabledWorkerId = AtomicValue<Either<WorkerId, Error>?>(nil)
        
        workerDisabler.disableWorker(
            workerId: workerId,
            callbackQueue: callbackQueue
        ) { (result: Either<WorkerId, Error>) in
            disabledWorkerId.set(result)
        }
        
        let queueResponse = try SynchronousWaiter().waitForUnwrap(
            timeout: 15,
            valueProvider: { disabledWorkerId.currentValue() },
            description: "Performing request to the queue"
        )
        do {
            Logger.always("Successfully disabled worker \(try queueResponse.dematerialize()) on queue \(queueServerAddress)")
        } catch {
            Logger.error("Failed to disabled worker \(workerId) on queue \(queueServerAddress): \(error)")
        }
    }
    
    
}
