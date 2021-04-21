import AtomicModels
import Foundation
import PathLib

public protocol RunnerWasteCollector {
    func scheduleCollection(path: AbsolutePath)
    
    var collectedPaths: Set<AbsolutePath> { get }
}

public final class RunnerWasteCollectorImpl: RunnerWasteCollector {
    private let items = AtomicValue<Set<AbsolutePath>>(Set())
    
    public init() {}
    
    public func scheduleCollection(path: AbsolutePath) {
        items.withExclusiveAccess { $0.insert(path) }
    }
    
    public var collectedPaths: Set<AbsolutePath> {
        items.currentValue()
    }
}
