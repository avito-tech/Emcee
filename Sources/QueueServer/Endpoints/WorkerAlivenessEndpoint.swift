import Dispatch
import Foundation
import Models
import RESTMethods
import RESTServer
import WorkerAlivenessTracker

public final class WorkerAlivenessEndpoint: RequestSignatureVerifyingRESTEndpoint {
    public typealias DecodedObjectType = ReportAliveRequest
    public typealias ResponseType = ReportAliveResponse

    private let workerAlivenessProvider: WorkerAlivenessProvider
    public let expectedRequestSignature: RequestSignature
    
    public init(
        workerAlivenessProvider: WorkerAlivenessProvider,
        expectedRequestSignature: RequestSignature
    ) {
        self.workerAlivenessProvider = workerAlivenessProvider
        self.expectedRequestSignature = expectedRequestSignature
    }
    
    public func handle(verifiedRequest: ReportAliveRequest) throws -> ReportAliveResponse {
        workerAlivenessProvider.set(
            bucketIdsBeingProcessed: verifiedRequest.bucketIdsBeingProcessed,
            workerId: verifiedRequest.workerId
        )
        return .aliveReportAccepted
    }
}
