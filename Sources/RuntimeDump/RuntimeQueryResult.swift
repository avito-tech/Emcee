import Foundation
import Models

public struct RuntimeQueryResult: Codable, Equatable {
    public let unavailableTestsToRun: [TestToRun]
    public let availableRuntimeTests: [RuntimeTestEntry]
}
