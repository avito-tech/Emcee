import AtomicModels
import EmceeLogging
import Foundation

public final class ConcurrentlyPerformedBenchmarks: Benchmark {
    private let benchmarksToExecute: [String: Benchmark]
    private let maximumParallelExecutionCount: Int
    
    public init(
        benchmarksToExecute: [String: Benchmark],
        maximumParallelExecutionCount: Int? = nil
    ) {
        self.benchmarksToExecute = benchmarksToExecute
        self.maximumParallelExecutionCount = maximumParallelExecutionCount ?? benchmarksToExecute.count
    }
    
    public var name: String {
        "\(benchmarksToExecute.count) benchmarks performed concurrently in \(maximumParallelExecutionCount) parallel tasks"
    }
    
    public func run(contextualLogger: ContextualLogger) -> BenchmarkResult {
        let operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = maximumParallelExecutionCount
        
        let results = AtomicValue<[String: BenchmarkResult]>([:])
        
        for namedBenchmark in benchmarksToExecute {
            operationQueue.addOperation {
                contextualLogger.info("Concurrently running benchmark: \(namedBenchmark.value.name)")
                let result = namedBenchmark.value.run(contextualLogger: contextualLogger)
                results.withExclusiveAccess {
                    $0[namedBenchmark.key] = result
                }
            }
        }
        
        operationQueue.waitUntilAllOperationsAreFinished()
        
        return MappedBenchmarkResult(results: results.currentValue())
    }
}
