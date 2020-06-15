import AtomicModels
import Foundation
import Logging
import Runner

public final class XcodebuildOutputProcessor {
    private let xcodebuildLogParser: XcodebuildLogParser
    private let testRunnerStream: TestRunnerStream
    private let collectedBytes = AtomicValue(Data())
    
    public init(
        testRunnerStream: TestRunnerStream,
        xcodebuildLogParser: XcodebuildLogParser
    ) {
        self.testRunnerStream = testRunnerStream
        self.xcodebuildLogParser = xcodebuildLogParser
    }
    
    public func newStdout(data: Data) {
        let data = collectedBytes.currentValue() + data
        
        let dataChunks = data.split(separator: 0x0A)
        
        for chunkIndex in 0 ..< dataChunks.count {
            let dataChunk = dataChunks[chunkIndex]
            
            guard let string = String(data: dataChunk, encoding: .utf8) else {
                for index in chunkIndex ..< dataChunks.count {
                    collectedBytes.withExclusiveAccess { $0.append(dataChunks[index]) }
                }
                Logger.debug("Can't obtain string from xcodebuild stdout \(data.count) bytes, will shift data (\(collectedBytes.currentValue().count) bytes) to the next stdout event")
                break
            }
            
            collectedBytes.set(Data())
            
            do {
                try xcodebuildLogParser.parse(string: string, testRunnerStream: testRunnerStream)
            } catch {
                Logger.warning("Failed to parse xcodebuild output: \(error). This error will be ignored.")
            }
        }
    }
}
