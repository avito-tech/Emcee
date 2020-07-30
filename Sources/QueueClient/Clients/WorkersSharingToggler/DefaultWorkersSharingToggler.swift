import RequestSender
import AtomicModels
import Foundation
import RequestSender
import RESTMethods
import SynchronousWaiter
import Types

public class DefaultWorkersSharingToggler: WorkersSharingToggler {
    private let callbackQueue = DispatchQueue(label: "DisableWorkersSharingCommand.callbackQueue")
    private let timeout: TimeInterval
    private let requestSender: RequestSender
    private let waiter = SynchronousWaiter()
    
    public init(timeout: TimeInterval, requestSender: RequestSender) {
        self.timeout = timeout
        self.requestSender = requestSender
    }
    
    public func setSharingStatus(_ status: WorkersSharingFeatureStatus) throws {
        let callbackWaiter: CallbackWaiter<Error?> = waiter.createCallbackWaiter()
        
        requestSender.sendRequestWithCallback(
            request: ToggleWorkersSharingRequest(payload: ToggleWorkersSharingPayload(status: status)),
            callbackQueue: callbackQueue
        ) { (result: Either<VoidPayload, RequestSenderError>) in
            callbackWaiter.set(result: result.right)
        }
        
        if let error = try callbackWaiter.wait(timeout: timeout, description: "Set worker sharing status to \(status) on queue") {
            throw error
        }
    }
}
