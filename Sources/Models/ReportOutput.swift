import Foundation

public struct ReportOutput: Codable {
    /** Absolute path where Junit report should be created. */
    public let junit: String
    
    /** Absolute path where Chrome Tracing report should be created. */
    public let tracingReport: String
    
    public static let devNullOutput = ReportOutput(junit: "/dev/null", tracingReport: "/dev/null")

    public init(junit: String, tracingReport: String) {
        self.junit = junit
        self.tracingReport = tracingReport
    }
}
