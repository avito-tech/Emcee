import Dispatch
import Foundation
import QueueModels
import RESTMethods
import RequestSender
import Types

public final class BucketResultSenderImpl: BucketResultSender {
    private let requestSender: RequestSender
    
    public init(requestSender: RequestSender) {
        self.requestSender = requestSender
    }
    
    public func send(
        bucketId: BucketId,
        testingResult: TestingResult,
        workerId: WorkerId,
        payloadSignature: PayloadSignature,
        callbackQueue: DispatchQueue,
        completion: @escaping (Either<BucketId, Error>) -> ()
    ) {
        let request = BucketResultRequest(
            payload: BucketResultPayload(
                bucketId: bucketId,
                workerId: workerId,
                testingResult: testingResult,
                payloadSignature: payloadSignature
            )
        )

        requestSender.sendRequestWithCallback(
            request: request,
            callbackQueue: callbackQueue,
            callback: { (response: Either<BucketResultAcceptResponse, RequestSenderError>) in
                do {
                    let value = try response.dematerialize()
                    switch value {
                    case .bucketResultAccepted(let bucketId):
                        completion(Either<BucketId, Error>.success(bucketId))
                    }
                } catch {
                    completion(Either<BucketId, Error>.error(error))
                }
            }
        )
    }
}
