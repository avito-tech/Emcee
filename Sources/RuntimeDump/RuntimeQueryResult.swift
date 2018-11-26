import Foundation
import Models

public struct RuntimeQueryResult {
    public let unavailableTestsToRun: [TestToRun]
    public let availableRuntimeTests: [RuntimeTestEntry]
}
