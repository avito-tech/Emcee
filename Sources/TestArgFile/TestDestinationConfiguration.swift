import Foundation
import RunnerModels
import SimulatorPoolModels
import TestDestination

public struct TestDestinationConfiguration: Codable, Equatable {
    public let testDestination: AppleTestDestination
    public let reportOutput: ReportOutput

    public init(testDestination: AppleTestDestination, reportOutput: ReportOutput) {
        self.testDestination = testDestination
        self.reportOutput = reportOutput
    }
}
