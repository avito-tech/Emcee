import Foundation
import RunnerModels
import SimulatorPoolModels

public struct TestDestinationConfiguration: Codable, Equatable {
    public let testDestination: TestDestination
    public let reportOutput: ReportOutput

    public init(testDestination: TestDestination, reportOutput: ReportOutput) {
        self.testDestination = testDestination
        self.reportOutput = reportOutput
    }
}
