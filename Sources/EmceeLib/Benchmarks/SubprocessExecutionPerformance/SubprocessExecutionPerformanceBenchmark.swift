import Benchmarking
import EmceeLogging
import Foundation
import PathLib
import PlistLib
import ProcessController
//
//public final class SubprocessExecutionPerformanceBenchmark: Benchmark {
//    private let measurer: Measurer
//    private let processControllerProvider: ProcessControllerProvider
//    private let subprocess: Subprocess
//    
//    public init(
//        measurer: Measurer,
//        processControllerProvider: ProcessControllerProvider,
//        subprocess: Subprocess
//    ) {
//        self.measurer = measurer
//        self.processControllerProvider = processControllerProvider
//        self.subprocess = subprocess
//    }
//    
//    public var name: String {
//        "Execute \(subprocess)"
//    }
//    
//    public func run(contextualLogger: ContextualLogger) -> BenchmarkResult {
//        do {
//            let processController = try processControllerProvider.createProcessController(
//                subprocess: subprocess
//            )
//            return SubprocessExecutionPerformanceBenchmarkResult(
//                measurementResult: measurer.measure {
//                    try processController.startAndWaitForSuccessfulTermination()
//                },
//                subprocess: subprocess
//            )
//        } catch {
//            return ErrorBenchmarkResult(error: error)
//        }
//    }
//}
