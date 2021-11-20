import EmceeLogging
import Foundation

public final class ConditionallyRepeatedBenchmark: Benchmark {
    private let benchmarkToExecute: Benchmark
    private let condition: () -> Bool
    
    public var name: String {
        "Conditionally repeated benchmark \(benchmarkToExecute.name)"
    }
    
    /// - Parameters:
    ///   - benchmarkToExecute: Benchmark to run repeatedly while condition allows to do so
    ///   - condition: A condition which allows (`true`) or stops (`false`) benchmark execution.
    public init(
        benchmarkToExecute: Benchmark,
        condition: @escaping () -> Bool
    ) {
        self.benchmarkToExecute = benchmarkToExecute
        self.condition = condition
    }
    
    public func run(contextualLogger: ContextualLogger) -> BenchmarkResult {
        var results = [BenchmarkResult]()
        
        while condition() {
            results.append(
                benchmarkToExecute.run(contextualLogger: contextualLogger)
            )
        }
        
        return MultipleBenchmarkResult(results: results)
    }
}
