import Foundation
import Runner

public class FakeRunnerWasteCollectorProvider: RunnerWasteCollectorProvider {
    public var resultProvider: () -> RunnerWasteCollector
    
    public init(
        resultProvider: @escaping () -> RunnerWasteCollector = { RunnerWasteCollectorImpl() }
    ) {
        self.resultProvider = resultProvider
    }
    
    public func createRunnerWasteCollector() -> RunnerWasteCollector {
        resultProvider()
    }
}
