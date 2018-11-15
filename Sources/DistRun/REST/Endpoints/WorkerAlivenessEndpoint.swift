import Dispatch
import Foundation
import Models
import RESTMethods

public final class WorkerAlivenessEndpoint: RESTEndpoint {
    public typealias T = ReportAliveRequest
    
    private let alivenessTracker: WorkerAlivenessTracker
    
    public init(alivenessTracker: WorkerAlivenessTracker) {
        self.alivenessTracker = alivenessTracker
    }
    
    public func handle(decodedRequest: ReportAliveRequest) throws -> RESTResponse {
        alivenessTracker.workerIsAlive(workerId: decodedRequest.workerId)
        return .aliveReportAccepted
    }
}
