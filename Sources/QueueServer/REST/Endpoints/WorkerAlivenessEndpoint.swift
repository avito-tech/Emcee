import Dispatch
import Foundation
import Models
import RESTMethods
import WorkerAlivenessTracker

public final class WorkerAlivenessEndpoint: RequestSignatureVerifyingRESTEndpoint {
    public typealias DecodedObjectType = ReportAliveRequest
    public typealias ResponseType = ReportAliveResponse

    private let alivenessTracker: WorkerAlivenessTracker
    public let expectedRequestSignature: RequestSignature
    
    public init(
        alivenessTracker: WorkerAlivenessTracker,
        expectedRequestSignature: RequestSignature
    ) {
        self.alivenessTracker = alivenessTracker
        self.expectedRequestSignature = expectedRequestSignature
    }
    
    public func handle(verifiedRequest: ReportAliveRequest) throws -> ReportAliveResponse {
        alivenessTracker.markWorkerAsAlive(workerId: verifiedRequest.workerId)
        alivenessTracker.set(
            bucketIdsBeingProcessed: verifiedRequest.bucketIdsBeingProcessed,
            workerId: verifiedRequest.workerId
        )
        return .aliveReportAccepted
    }
}
