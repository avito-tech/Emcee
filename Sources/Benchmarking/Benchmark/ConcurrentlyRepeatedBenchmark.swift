import AtomicModels
import EmceeLogging
import Foundation

public final class ConcurrentlyRepeatedBenchmark: Benchmark {
    private let benchmarkToExecute: Benchmark
    private let repeatCount: Int
    private let maximumParallelExecutionCount: Int
    
    public init(
        benchmarkToExecute: Benchmark,
        repeatCount: Int,
        maximumParallelExecutionCount: Int
    ) {
        self.benchmarkToExecute = benchmarkToExecute
        self.repeatCount = repeatCount
        self.maximumParallelExecutionCount = maximumParallelExecutionCount
    }
    
    public var name: String {
        "\(benchmarkToExecute.name) benchmark performed \(repeatCount) times concurrently in \(maximumParallelExecutionCount) parallel runs"
    }
    
    public func run(contextualLogger: ContextualLogger) -> BenchmarkResult {
        let operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = maximumParallelExecutionCount
        
        let results = AtomicValue<[BenchmarkResult]>([])
        
        for _ in 0..<repeatCount {
            operationQueue.addOperation { [benchmarkToExecute] in
                let result = benchmarkToExecute.run(contextualLogger: contextualLogger)
                results.withExclusiveAccess {
                    $0.append(result)
                }
            }
        }
        
        operationQueue.waitUntilAllOperationsAreFinished()
        
        return MultipleBenchmarkResult(results: results.currentValue())
    }
}
