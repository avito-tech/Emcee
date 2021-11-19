import Foundation

public final class MultipleBenchmarkResult: BenchmarkResult {
    private let results: [BenchmarkResult]
    
    public init(results: [BenchmarkResult]) {
        self.results = results
    }

    public func toCsv() -> String {
        results.map {
            $0.toCsv()
        }.joined(separator: "\n")
    }
}
