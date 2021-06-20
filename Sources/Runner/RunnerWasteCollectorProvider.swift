import Foundation

public protocol RunnerWasteCollectorProvider {
    func createRunnerWasteCollector() -> RunnerWasteCollector
}

public final class RunnerWasteCollectorProviderImpl: RunnerWasteCollectorProvider {
    public init() {}
    
    public func createRunnerWasteCollector() -> RunnerWasteCollector { RunnerWasteCollectorImpl() }
}
