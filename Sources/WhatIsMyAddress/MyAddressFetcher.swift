import Dispatch
import Types

public protocol MyAddressFetcher {
    /// Queries remote end (usually a queue) for how it sees requester's address. 
    /// This allows queue to communicate to the requester, assuming it is not behind NAT.
    func fetch(
        queue: DispatchQueue,
        completion: @escaping (Either<String, Error>) -> ()
    )
}
