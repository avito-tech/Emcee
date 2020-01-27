import Foundation
import Models

public struct RuntimeQueryResult: Codable {
    public let unavailableTestsToRun: [TestToRun]
    public let availableRuntimeTests: [RuntimeTestEntry]
}
