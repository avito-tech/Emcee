import Deployer
import Models
import RESTMethods
import RESTServer

public final class WorkersToUtilizeEndpoint: RESTEndpoint {
    public init() { }
    
    public func handle(decodedPayload: [DeploymentDestination]) throws -> WorkersToUtilizeResponse {
        return .workersToUtilize(
            workerIds: Set(decodedPayload.map { $0.workerId })
        )
    }
}
