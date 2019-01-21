import Foundation

public class JobResults: Codable, CustomStringConvertible, Equatable {
    public let jobId: JobId
    public let testingResults: [TestingResult]

    public init(jobId: JobId, testingResults: [TestingResult]) {
        self.jobId = jobId
        self.testingResults = testingResults
    }
    
    public var description: String {
        return "<\(type(of: self)) job: \(jobId) results: \(testingResults)>"
    }
    
    public static func == (left: JobResults, right: JobResults) -> Bool {
        return left.jobId == right.jobId
            && left.testingResults == right.testingResults
    }
}

