import Foundation
import Models

public struct RuntimeQueryResult: Codable, Equatable, CustomStringConvertible {
    public let unavailableTestsToRun: [TestToRun]
    public let testsInRuntimeDump: TestsInRuntimeDump

    public var description: String {
        return "Runtime dump query: \(testsInRuntimeDump.tests.count) tests, missing tests: \(unavailableTestsToRun)"
    }
}
