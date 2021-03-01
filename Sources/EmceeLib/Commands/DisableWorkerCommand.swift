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

public final class DisableWorkerCommand: Command {
    public let name = "disableWorker"
    
    public let description = "Disables the provided worker: queue won't let it execute further jobs"
    
    public var arguments: Arguments = [
        ArgumentDescriptions.queueServer.asRequired,
        ArgumentDescriptions.workerId.asRequired,
    ]
    
    private let callbackQueue = DispatchQueue(label: "DisableWorkerCommand.callbackQueue")
    private let di: DI
    
    public init(di: DI) throws {
        self.di = di
    }
    
    public func run(payload: CommandPayload) throws {
        let queueServerAddress: SocketAddress = try payload.expectedSingleTypedValue(argumentName: ArgumentDescriptions.queueServer.name)
        let workerId: WorkerId = try payload.expectedSingleTypedValue(argumentName: ArgumentDescriptions.workerId.name)
        
        let workerDisabler = WorkerDisablerImpl(
            requestSender: try di.get(RequestSenderProvider.self).requestSender(
                socketAddress: queueServerAddress
            )
        )
        
        let callbackWaiter: CallbackWaiter<Either<WorkerId, Error>> = try di.get(Waiter.self).createCallbackWaiter()
        
        workerDisabler.disableWorker(
            workerId: workerId,
            callbackQueue: callbackQueue
        ) { (result: Either<WorkerId, Error>) in
            callbackWaiter.set(result: result)
        }
        
        let disabledWorkerId = try callbackWaiter.wait(timeout: 15, description: "Request to disable \(workerId) on queue")
        
        do {
            Logger.always("Successfully disabled worker \(try disabledWorkerId.dematerialize()) on queue \(queueServerAddress)")
        } catch {
            Logger.error("Failed to disabled worker \(workerId) on queue \(queueServerAddress): \(error)")
        }
    }
}
