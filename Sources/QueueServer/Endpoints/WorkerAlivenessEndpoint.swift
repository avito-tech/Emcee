import Dispatch
import Foundation
import Models
import RESTMethods
import RESTServer
import WorkerAlivenessProvider

public final class WorkerAlivenessEndpoint: PayloadSignatureVerifyingRESTEndpoint {
    public typealias DecodedObjectType = ReportAlivePayload
    public typealias ResponseType = ReportAliveResponse

    private let workerAlivenessProvider: WorkerAlivenessProvider
    public let expectedPayloadSignature: PayloadSignature
    
    public init(
        workerAlivenessProvider: WorkerAlivenessProvider,
        expectedRequestSignature: PayloadSignature
    ) {
        self.workerAlivenessProvider = workerAlivenessProvider
        self.expectedPayloadSignature = expectedRequestSignature
    }
    
    public func handle(verifiedPayload: ReportAlivePayload) throws -> ReportAliveResponse {
        workerAlivenessProvider.set(
            bucketIdsBeingProcessed: verifiedPayload.bucketIdsBeingProcessed,
            workerId: verifiedPayload.workerId
        )
        return .aliveReportAccepted
    }
}
