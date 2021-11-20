import EmceeLogging
import Foundation

public final class SequentiallyRepeatedBenchmark: Benchmark {
    private let benchmarkToExecute: Benchmark
    private let repeatCount: Int
    
    public init(
        benchmarkToExecute: Benchmark,
        repeatCount: Int
    ) {
        self.benchmarkToExecute = benchmarkToExecute
        self.repeatCount = repeatCount
    }
    
    public var name: String {
        "\(benchmarkToExecute.name) benchmark performed \(repeatCount) times sequentially"
    }
    
    public func run(contextualLogger: ContextualLogger) -> BenchmarkResult {
        var results = [BenchmarkResult]()
        
        for _ in 0..<repeatCount {
            results.append(
                benchmarkToExecute.run(contextualLogger: contextualLogger)
            )
        }
        
        return MultipleBenchmarkResult(results: results)
    }
}
