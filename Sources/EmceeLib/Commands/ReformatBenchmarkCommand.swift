import ArgLib
import DI
import Foundation
import PlistLib
import PathLib
import Types

public final class ReformatPlistCommand: Command {
    public let name = "reformat"
    public let description = "Reformat"
    public let arguments: Arguments = [
        ArgumentDescriptions.plist.asRequired,
    ]
    
    private let di: DI

    public init(di: DI) throws {
        self.di = di
    }
    
    public func run(payload: CommandPayload) throws {
        let path: AbsolutePath = try payload.expectedSingleTypedValue(argumentName: ArgumentDescriptions.plist.name)
        
        let plist = try Plist.create(fromData: Data(contentsOf: path.fileUrl))
        let metricsArray = try plist.root.plistEntry.dictEntry()["metrics"]!
        
        try printSystemMetricsTable(metricsArray: metricsArray)
        
        let testResultsArray = try plist.root.plistEntry.dictEntry()["testResults"]!
        try printTestMetricsTable(testResultsArray: testResultsArray)
    }
    
    private func printSystemMetricsTable(metricsArray: PlistEntry) throws {
        print("Metrics CSV:")
        print(
            "timestamp",
            "cpuLoad",
            "numberOfRunningProcesses",
            "numberOfOpenedFiles",
            "freeMemory",
            "usedMemory",
            "swapSizeInMb",
            "loadAverage1min",
            "loadAverage5min",
            "loadAverage15min",
            separator: ";"
        )
        
        for metricsEntry in try metricsArray.arrayEntry() {
            print(
                try metricsEntry.dictEntry()["timestamp"]!.numberValue(),
                try metricsEntry.dictEntry()["cpuLoad"]!.numberValue(),
                try metricsEntry.dictEntry()["numberOfRunningProcesses"]!.numberValue(),
                try metricsEntry.dictEntry()["numberOfOpenedFiles"]!.numberValue(),
                try metricsEntry.dictEntry()["freeMemory"]!.numberValue(),
                try metricsEntry.dictEntry()["usedMemory"]!.numberValue(),
                try metricsEntry.dictEntry()["swapSizeInMb"]!.numberValue(),
                try metricsEntry.dictEntry()["loadAverage1min"]!.numberValue(),
                try metricsEntry.dictEntry()["loadAverage5min"]!.numberValue(),
                try metricsEntry.dictEntry()["loadAverage15min"]!.numberValue(),
                separator: ";"
            )
        }
    }
    
    private func printTestMetricsTable(testResultsArray: PlistEntry) throws {
        struct _TestRunResult {
            let success: Bool
            let duration: Double
        }
        
        var testRunsByTestName = MapWithCollection<String, _TestRunResult>()
        
        for simulatorAggregatedItem in try testResultsArray.arrayEntry() {
            for allTestRunsOnSimulatorItem in try simulatorAggregatedItem.arrayEntry() {
                for singleTestRun in try allTestRunsOnSimulatorItem.arrayEntry() {
                    for singleTestRunInfo in try singleTestRun.arrayEntry() {
                        let testName = try singleTestRunInfo.dictEntry()["testName"]!.stringValue()
                        let testRunResults = try singleTestRunInfo.dictEntry()["testRunResults"]!.arrayEntry()
                        
                        for testRunResult in testRunResults {
                            let duration = try testRunResult.dictEntry()["duration"]!.numberValue()
                            let succeeded =  try testRunResult.dictEntry()["succeeded"]!.boolValue()
                            
                            testRunsByTestName.append(
                                key: testName,
                                element: _TestRunResult(success: succeeded, duration: duration)
                            )
                        }
                    }
                }
            }
        }
        
        print("Will output per-test results below")
        for keyValue in testRunsByTestName.asDictionary {
            let testName = keyValue.key
            let testResults = keyValue.value
            
            print("Test results for \(testName):")
            print("   - \(testResults.count) runs")
            print("   - \(testResults.filter { $0.success }.count) successes")
            print("   - \(testResults.filter { !$0.success }.count) failures")
            print("   - min duration: \(testResults.map { $0.duration }.min() ?? 0.0)")
            print("   - p50 duration: \(testResults.map { $0.duration }.percentile(probability: 0.50) ?? 0.0)")
            print("   - p75 duration: \(testResults.map { $0.duration }.percentile(probability: 0.75) ?? 0.0)")
            print("   - p90 duration: \(testResults.map { $0.duration }.percentile(probability: 0.90) ?? 0.0)")
            print("   - p99 duration: \(testResults.map { $0.duration }.percentile(probability: 0.99) ?? 0.0)")
            print("   - max duration: \(testResults.map { $0.duration }.max() ?? 0.0)")
            print("Complete data points:")
            print("duration", "success", separator: ";")
            for result in testResults {
                print(result.duration, result.success, separator: ";")
            }
            print("-----------------------------------------------------------")
        }
    }
}

private extension Array where Element == Double {
    func percentile(probability: Double) -> Double? {
      if probability < 0 || probability > 1 { return nil }
      let data = self.sorted(by: <)
      let count = Double(data.count)
      let m = 1.0 - probability
      let k = Int((probability * count) + m)
      let probability = (probability * count) + m - Double(k)
      return qDef(data, k: k, probability: probability)
    }
    
    private func qDef(_ data: [Double], k: Int, probability: Double) -> Double? {
      if data.isEmpty { return nil }
      if k < 1 { return data[0] }
      if k >= data.count { return data.last }
      return ((1.0 - probability) * data[k - 1]) + (probability * data[k])
    }
}
