import Foundation
import Models

public enum RequestType: String, Codable {
    case registerWorker
    case bucketFetch
    case bucketResult
    case reportAlive
}

public final class RegisterWorkerRequest: Codable {
    public let requestType = RequestType.registerWorker
    public let workerId: String
    
    public init(workerId: String) {
        self.workerId = workerId
    }
}

public final class BucketFetchRequest: Codable {
    public let requestType = RequestType.bucketFetch
    public let workerId: String
    public let requestId: String
    
    public init(workerId: String, requestId: String) {
        self.workerId = workerId
        self.requestId = requestId
    }
}

public final class BucketResultRequest: Codable {
    public let requestType = RequestType.bucketResult
    public let workerId: String
    public let requestId: String
    public let testingResult: TestingResult
    
    public init(workerId: String, requestId: String, testingResult: TestingResult) {
        self.workerId = workerId
        self.requestId = requestId
        self.testingResult = testingResult
    }
}

public final class ReportAliveRequest: Codable {
    public let requestType = RequestType.reportAlive
    public let workerId: String
    public let bucketIdsBeingProcessed: Set<String>
    
    public init(workerId: String, bucketIdsBeingProcessed: Set<String>) {
        self.workerId = workerId
        self.bucketIdsBeingProcessed = bucketIdsBeingProcessed
    }
}
