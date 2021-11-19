import Foundation
import PlistLib

public final class ErrorBenchmarkResult: BenchmarkResult {
    private let error: Error
    
    public init(error: Error) {
        self.error = error
    }

    public func toCsv() -> String {
        error.localizedDescription
    }
}
