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
            contextualLogger.info("Running benchmark \(benchmarkToExecute.name) while condition allows to run it")
            results.append(
                benchmarkToExecute.run(contextualLogger: contextualLogger)
            )
        }
        
        contextualLogger.info("Stopped running benchmark \(benchmarkToExecute.name) because condition disallowed to run it. Got \(results.count) results.")
        
        return MultipleBenchmarkResult(results: results)
    }
}
