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
    
    public init(timeout: TimeInterval, requestSender: RequestSender) {
        self.timeout = timeout
        self.requestSender = requestSender
    }
    
    public func setSharingStatus(_ status: WorkersSharingFeatureStatus) throws {
        var requestResult: Either<VoidPayload, RequestSenderError>?
        
        requestSender.sendRequestWithCallback(
            request: ToggleWorkersSharingRequest(payload: ToggleWorkersSharingPayload(status: status)),
            callbackQueue: callbackQueue) { (result: Either<VoidPayload, RequestSenderError>)in
                requestResult = result
        }

        _ = try SynchronousWaiter().waitForUnwrap(
           timeout: timeout,
           valueProvider: { try requestResult?.dematerialize() },
           description: "Performing request to the queue"
        )
    }
}
