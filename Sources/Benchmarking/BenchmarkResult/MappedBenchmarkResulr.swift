import Foundation
import PlistLib

public final class MappedBenchmarkResult: BenchmarkResult {
    public let results: [String: BenchmarkResult]
    
    public init(results: [String: BenchmarkResult]) {
        self.results = results
    }
    
    public func toCsv() -> String {
        let sorted = results.sorted { (l, r) -> Bool in
            l.key < r.key
        }
        return [
            sorted.map { $0.value.toCsv() }.joined(separator: ";"),
        ].joined(separator: "\n")
    }
}
