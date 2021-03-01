import ArgLib
import AtomicModels
import DI
import Foundation
import EmceeLogging
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
    private let di: DI
    
    public init(di: DI) throws {
        self.di = di
    }
    
    public func run(payload: CommandPayload) throws {
        let queueServerAddress: SocketAddress = try payload.expectedSingleTypedValue(argumentName: ArgumentDescriptions.queueServer.name)
        let workerId: WorkerId = try payload.expectedSingleTypedValue(argumentName: ArgumentDescriptions.workerId.name)
        
        let workerEnabler = WorkerEnablerImpl(
            requestSender: try di.get(RequestSenderProvider.self).requestSender(
                socketAddress: queueServerAddress
            )
        )
        
        let callbackWaiter: CallbackWaiter<Either<WorkerId, Error>> = try di.get(Waiter.self).createCallbackWaiter()
        
        workerEnabler.enableWorker(
            workerId: workerId,
            callbackQueue: callbackQueue
        ) { (result: Either<WorkerId, Error>) in
            callbackWaiter.set(result: result)
        }
        
        let enabledWorkerId = try callbackWaiter.wait(timeout: 15, description: "Request to enable worker \(workerId) on queue")
        do {
            Logger.always("Successfully enabled worker \(try enabledWorkerId.dematerialize()) on queue \(queueServerAddress)")
        } catch {
            Logger.error("Failed to enable worker \(workerId) on queue \(queueServerAddress): \(error)")
        }
    }
    
    
}
