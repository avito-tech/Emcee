import Foundation
import RequestSender
import Types

public final class MyAddressFetcherImpl: MyAddressFetcher {
    private let requestSender: RequestSender
    
    public init(
        requestSender: RequestSender
    ) {
        self.requestSender = requestSender
    }
    
    public func fetch(
        queue: DispatchQueue,
        completion: @escaping (Either<String, Error>) -> ()
    ) {
        requestSender.sendRequestWithCallback(
            request: WhatIsMyAddressRequest(payload: WhatIsMyAddressPayload()),
            callbackQueue: queue,
            callback: { (response: Either<WhatIsMyAddressRequest.Response, RequestSenderError>) in
                completion(
                    response.mapResult { $0.address }
                )
            }
        )
    }
}
