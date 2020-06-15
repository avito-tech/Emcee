import Deployer
import Models
import QueueCommunication
import RESTInterfaces
import RESTMethods
import RESTServer

public final class WorkersToUtilizeEndpoint: RESTEndpoint {
    public let path: RESTPath = RESTMethod.workersToUtilize
    public let requestIndicatesActivity = false
    
    private let service: WorkersToUtilizeService
    
    public init(service: WorkersToUtilizeService) {
        self.service = service
    }
    
    public func handle(payload: WorkersToUtilizePayload) throws -> WorkersToUtilizeResponse {
        return .workersToUtilize(
            workerIds: Set(service.workersToUtilize(
                deployments: payload.deployments,
                version: payload.version
            ))
        )
    }
}
