import Dispatch
import Foundation
import Models
import RESTMethods
import WorkerAlivenessTracker

public final class WorkerAlivenessEndpoint: RESTEndpoint {
    public typealias T = ReportAliveRequest
    
    private let alivenessTracker: WorkerAlivenessTracker
    
    public init(alivenessTracker: WorkerAlivenessTracker) {
        self.alivenessTracker = alivenessTracker
    }
    
    public func handle(decodedRequest: ReportAliveRequest) throws -> RESTResponse {
        alivenessTracker.markWorkerAsAlive(workerId: decodedRequest.workerId)
        return .aliveReportAccepted
    }
}
