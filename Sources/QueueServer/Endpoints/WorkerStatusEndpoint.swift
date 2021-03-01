import Dispatch
import DistWorkerModels
import Foundation
import EmceeLogging
import RESTInterfaces
import RESTMethods
import RESTServer
import WorkerAlivenessProvider

public final class WorkerStatusEndpoint: RESTEndpoint {
    private let workerAlivenessProvider: WorkerAlivenessProvider
    public let path: RESTPath = RESTMethod.workerStatus
    public let requestIndicatesActivity = false
    
    public init(
        workerAlivenessProvider: WorkerAlivenessProvider
    ) {
        self.workerAlivenessProvider = workerAlivenessProvider
    }
    
    public func handle(payload: WorkerStatusPayload) throws -> WorkerStatusResponse {
        let aliveness = workerAlivenessProvider.workerAliveness
        
        return WorkerStatusResponse(workerAliveness: aliveness)
    }
}
