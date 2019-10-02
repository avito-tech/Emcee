import Dispatch
import Foundation
import Models
import RESTMethods
import RequestSender

public final class BucketResultSenderImpl: BucketResultSender {
    private let requestSender: RequestSender
    
    public init(requestSender: RequestSender) {
        self.requestSender = requestSender
    }
    
    public func send(
        testingResult: TestingResult,
        requestId: RequestId,
        workerId: WorkerId,
        requestSignature: RequestSignature,
        callbackQueue: DispatchQueue,
        completion: @escaping (Either<BucketId, Error>) -> ()
    ) {
        requestSender.sendRequestWithCallback(
            pathWithSlash: RESTMethod.bucketResult.withPrependingSlash,
            payload: PushBucketResultRequest(
                workerId: workerId,
                requestId: requestId,
                testingResult: testingResult,
                requestSignature: requestSignature
        	),
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
