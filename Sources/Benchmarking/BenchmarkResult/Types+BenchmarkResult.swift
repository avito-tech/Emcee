import Foundation

extension String: BenchmarkResult {
    public func toCsv() -> String { self }
}

extension Int: BenchmarkResult {
    public func toCsv() -> String { "\(self)" }
}

extension Double: BenchmarkResult {
    public func toCsv() -> String { "\(self)" }
}

extension Bool: BenchmarkResult {
    public func toCsv() -> String { "\(self)" }
}
