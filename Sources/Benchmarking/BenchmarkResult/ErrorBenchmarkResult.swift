import Foundation
import PlistLib

public final class ErrorBenchmarkResult: BenchmarkResult {
    private let error: Error
    
    public init(error: Error) {
        self.error = error
    }
    
    public func plistEntry() -> PlistEntry {
        return .dict([
            "errorDescription": .string("\(error)"),
            "errorLocalizedDescription": .string(error.localizedDescription),
        ])
    }
}
