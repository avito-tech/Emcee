import Foundation

public struct TestDestinationConfiguration: Codable {
    /** Test destination */
    public let testDestination: TestDestination
    
    /** Destination specific outputs. */
    public let reportOutput: ReportOutput

    public init(testDestination: TestDestination, reportOutput: ReportOutput) {
        self.testDestination = testDestination
        self.reportOutput = reportOutput
    }
}
