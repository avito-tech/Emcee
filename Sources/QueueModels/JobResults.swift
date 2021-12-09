import Foundation

public struct JobResults: Codable, CustomStringConvertible, Equatable {
    public let jobId: JobId
    public let bucketResults: [BucketResult]

    public init(jobId: JobId, bucketResults: [BucketResult]) {
        self.jobId = jobId
        self.bucketResults = bucketResults
    }
    
    public var description: String {
        return "<\(type(of: self)) job: \(jobId) results: \(bucketResults)>"
    }
}

