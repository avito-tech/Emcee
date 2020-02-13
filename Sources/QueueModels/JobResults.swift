import Foundation
import Models

public struct JobResults: Codable, CustomStringConvertible, Equatable {
    public let jobId: JobId
    public let testingResults: [TestingResult]

    public init(jobId: JobId, testingResults: [TestingResult]) {
        self.jobId = jobId
        self.testingResults = testingResults
    }
    
    public var description: String {
        return "<\(type(of: self)) job: \(jobId) results: \(testingResults)>"
    }
}

