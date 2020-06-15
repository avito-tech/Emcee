import Deployer
import Models
import RESTInterfaces
import RESTMethods
import RESTServer

public final class WorkersToUtilizeEndpoint: RESTEndpoint {
    public var path: RESTPath = RESTMethod.workersToUtilize
    
    public let requestIndicatesActivity = false
    
    public init() { }
    
    public func handle(payload: [DeploymentDestination]) throws -> WorkersToUtilizeResponse {
        return .workersToUtilize(
            workerIds: Set(payload.map { $0.workerId })
        )
    }
}
