import Foundation
import PlistLib

public final class MappedBenchmarkResult: BenchmarkResult {
    private let results: [String: PlistEntry]
    
    public init(results: [String: BenchmarkResult]) {
        self.results = results.mapValues { $0.plistEntry() }
    }
    
    public init(results: [String: PlistEntry]) {
        self.results = results
    }
    
    public func plistEntry() -> PlistEntry {
        return .dict(results)
    }
}
