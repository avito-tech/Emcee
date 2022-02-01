import Foundation
import SynchronousWaiter
import Types

public final class SynchronousMyAddressFetcherImpl: SynchronousMyAddressFetcher {
    private let myAddressFetcher: MyAddressFetcher
    private let queue: DispatchQueue
    private let waiter: Waiter
    
    public init(
        myAddressFetcher: MyAddressFetcher,
        waiter: Waiter
    ) {
        self.myAddressFetcher = myAddressFetcher
        self.queue = DispatchQueue(label: "SynchronousMyAddressFetcherImpl.queue")
        self.waiter = waiter
    }
    
    public func fetch(
        timeout: TimeInterval
    ) throws -> String {
        let callbackWaiter: CallbackWaiter<Either<String, Error>> = waiter.createCallbackWaiter()
        myAddressFetcher.fetch(
            queue: queue
        ) { (result: Either<String, Error>) in
            callbackWaiter.set(result: result)
        }
        
        return try callbackWaiter.wait(
            timeout: timeout,
            description: "Wait for WhatIsMyAddress"
        ).dematerialize()
    }
}
