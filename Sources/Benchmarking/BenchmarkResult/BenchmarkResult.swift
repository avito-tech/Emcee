import Foundation
import PlistLib

public protocol BenchmarkResult {
    func toCsv() -> String
}
