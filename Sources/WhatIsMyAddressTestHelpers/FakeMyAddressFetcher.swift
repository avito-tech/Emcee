import Dispatch
import Types
import WhatIsMyAddress

public final class FakeMyAddressFetcher: MyAddressFetcher {
    public var resultProvider: () -> Either<String, Error>
    
    public init(
        resultProvider: @escaping () -> Either<String, Error>
    ) {
        self.resultProvider = resultProvider
    }
    
    public func fetch(queue: DispatchQueue, completion: @escaping (Either<String, Error>) -> ()) {
        completion(
            resultProvider()
        )
    }
}
