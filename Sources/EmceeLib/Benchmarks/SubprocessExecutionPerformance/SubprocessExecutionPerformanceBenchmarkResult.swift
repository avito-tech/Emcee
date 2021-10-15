import Benchmarking
import Foundation
import PlistLib
import ProcessController

public final class SubprocessExecutionPerformanceBenchmarkResult: BenchmarkResult {
    private let measurementResult: MeasurementResult<()>
    private let subprocess: Subprocess
    
    public init(
        measurementResult: MeasurementResult<()>,
        subprocess: Subprocess
    ) {
        self.measurementResult = measurementResult
        self.subprocess = subprocess
    }
    
    public func plistEntry() -> PlistEntry {
        return .dict([
            "duration": .number(measurementResult.duration),
            "executionFinishedSuccessfully": .bool(measurementResult.result.isSuccess),
            "subprocessDescription": .string("\(subprocess)"),
        ])
    }
}
