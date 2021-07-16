import Deployer
import EmceeLogging
import QueueCommunication
import RESTInterfaces
import RESTMethods
import RESTServer

public final class WorkersToUtilizeEndpoint: RESTEndpoint {
    public let path: RESTPath = RESTMethod.workersToUtilize
    public let requestIndicatesActivity = false
    
    private let logger: ContextualLogger
    private let service: WorkersToUtilizeService
    
    public init(
        logger: ContextualLogger,
        service: WorkersToUtilizeService
    ) {
        self.logger = logger
        self.service = service
    }
    
    public func handle(payload: WorkersToUtilizePayload) throws -> WorkersToUtilizeResponse {
        logger.debug("Received workers to utilize payload: \(payload)")
        return .workersToUtilize(
            workerIds: service.workersToUtilize(
                initialWorkerIds: payload.workerIds,
                queueInfo: payload.queueInfo
            )
        )
    }
}
