import Foundation

public struct ReportOutput: Codable, Equatable {
    /// Absolute path where Junit report should be created. If nil, report won't be created.
    public let junit: String?
    
    /// Absolute path where Chrome Tracing report should be created. If nil, report won't be created.
    public let tracingReport: String?

    public init(junit: String?, tracingReport: String?) {
        self.junit = junit
        self.tracingReport = tracingReport
    }
}
