import Foundation
import PlistLib

public final class MultipleBenchmarkResult: BenchmarkResult {
    private let results: [BenchmarkResult]
    
    public init(results: [BenchmarkResult]) {
        self.results = results
    }
    
    public func plistEntry() -> PlistEntry {
        return .array(results.map { $0.plistEntry() })
    }
}
