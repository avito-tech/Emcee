import EventBus
import Foundation
import Logging
import Models

final class EventBusListener: DefaultBusListener {
    private let outputPath: String
    private var testingResults = [TestingResult]()
    
    public init(outputPath: String) {
        self.outputPath = outputPath
    }
    
    override func didObtain(testingResult: TestingResult) {
        testingResults.append(testingResult)
    }
    
    override func tearDown() {
        dump()
    }
    
    private func dump() {
        do {
            let testNames = testingResults.flatMap { $0.unfilteredTestRuns.map { $0.testEntry.testName } }
            let encoder = JSONEncoder()
            let data = try encoder.encode(testNames)
            try data.write(to: URL(fileURLWithPath: outputPath))
        } catch {
            log("Error: \(error)", color: .red)
        }
    }
}
