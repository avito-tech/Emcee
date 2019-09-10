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
        completion: @escaping (Either<BucketId, RequestSenderError>) -> ()
    ) throws {
        try requestSender.sendRequestWithCallback(
            pathWithSlash: RESTMethod.bucketResult.withPrependingSlash,
            payload: PushBucketResultRequest(
                workerId: workerId,
                requestId: requestId,
                testingResult: testingResult,
                requestSignature: requestSignature
        	),
            callback: { (response: Either<BucketResultAcceptResponse, RequestSenderError>) in
                switch response {
                case .left(let value):
                    switch value {
                    case .bucketResultAccepted(let bucketId):
                        completion(.success(bucketId))
                    }
                case .right(let error):
                    completion(.error(error))
                }
            }
        )
    }
}
