import Foundation

public struct ReportOutput: Codable, Equatable {
    /// Path where Junit report should be created. If nil, report won't be created.
    public let junit: String?
    
    /// Path where Chrome Tracing report should be created. If nil, report won't be created.
    public let tracingReport: String?

    /// Path where merged xcresult should be create. If nil, result bundle won't be created
    public let resultBundle: String?
    
    public init(
        junit: String?,
        tracingReport: String?,
        resultBundle: String?
    ) {
        self.junit = junit
        self.tracingReport = tracingReport
        self.resultBundle = resultBundle
    }
}
