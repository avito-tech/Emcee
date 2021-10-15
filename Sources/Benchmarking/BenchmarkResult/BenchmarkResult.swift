import Foundation
import PlistLib

public protocol BenchmarkResult {
    func plistEntry() -> PlistEntry
}
