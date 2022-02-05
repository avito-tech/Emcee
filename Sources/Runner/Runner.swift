import Foundation
import RunnerModels

public protocol Runner {
    associatedtype C: RunnerConfiguration
    
    func runOnce(
        entriesToRun: [TestEntry],
        configuration: C
    ) throws -> RunnerRunResult
}
