import EmceeLogging
import Foundation


/// These benchmarks are executed one after another serially.
public final class SequentiallyPerformedBenchmarks: Benchmark {
    private let benchmarks: [Benchmark]
    
    public init(benchmarks: [Benchmark]) {
        self.benchmarks = benchmarks
    }
    
    public var name: String {
        "\(benchmarks.count) sequentially performed benchmarks"
    }
    
    public func run(contextualLogger: ContextualLogger) -> BenchmarkResult {
        return MultipleBenchmarkResult(
            results: benchmarks.map { benchmark in
                contextualLogger.info("Running benchmark sequentially: \(benchmark.name)")
                return benchmark.run(contextualLogger: contextualLogger)
            }
        )
    }
}
