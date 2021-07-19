import RequestSender
import RESTInterfaces
import RESTMethods
import RESTServer
import QueueModels

public final class WorkerIdsEndpoint: RESTEndpoint {
    public let path: RESTPath = RESTMethod.workerIds
    
    public let requestIndicatesActivity = false
    
    private let workerIds: Set<WorkerId>
    public init(workerIds: Set<WorkerId>) {
        self.workerIds = workerIds
    }
    
    public func handle(payload: VoidPayload) throws -> WorkerIdsResponse {
        WorkerIdsResponse(workerIds: workerIds)
    }
}

