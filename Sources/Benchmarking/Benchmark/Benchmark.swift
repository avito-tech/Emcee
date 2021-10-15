import EmceeLogging

public protocol Benchmark {
    var name: String { get }
    
    func run(contextualLogger: ContextualLogger) -> BenchmarkResult
}
