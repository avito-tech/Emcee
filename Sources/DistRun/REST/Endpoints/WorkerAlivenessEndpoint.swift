import Dispatch
import Foundation
import Models
import RESTMethods
import WorkerAlivenessTracker

public final class WorkerAlivenessEndpoint: RESTEndpoint {
    private let alivenessTracker: WorkerAlivenessTracker
    
    public init(alivenessTracker: WorkerAlivenessTracker) {
        self.alivenessTracker = alivenessTracker
    }
    
    public func handle(decodedRequest: ReportAliveRequest) throws -> ReportAliveResponse {
        alivenessTracker.markWorkerAsAlive(workerId: decodedRequest.workerId)
        alivenessTracker.set(
            bucketIdsBeingProcessed: decodedRequest.bucketIdsBeingProcessed,
            workerId: decodedRequest.workerId
        )
        return .aliveReportAccepted
    }
}
