import AtomicModels
import Foundation
import Logging
import Runner

public final class XcodebuildOutputProcessor {
    private let xcodebuildLogParser: XcodebuildLogParser
    private let testRunnerStream: TestRunnerStream
    private let previouslyUnparsedData = AtomicValue(Data())
    
    public init(
        testRunnerStream: TestRunnerStream,
        xcodebuildLogParser: XcodebuildLogParser
    ) {
        self.testRunnerStream = testRunnerStream
        self.xcodebuildLogParser = xcodebuildLogParser
    }
    
    public func newStdout(data newData: Data) {
        let maximumBufferSize = 100 * 1024
        
        let mergedData = previouslyUnparsedData.currentValue() + newData
        previouslyUnparsedData.set(Data())
        
        let dataChunks = mergedData.split(separator: 0x0A)
        
        for chunkIndex in 0 ..< dataChunks.count {
            let dataChunk = dataChunks[chunkIndex]
            
            guard let string = String(data: dataChunk, encoding: .utf8) else {
                for index in chunkIndex ..< dataChunks.count {
                    previouslyUnparsedData.withExclusiveAccess {
                        if $0.count + dataChunks[index].count < maximumBufferSize {
                            $0.append(dataChunks[index])
                        } else {
                            previouslyUnparsedData.set(Data())
                            Logger.debug("Buffer exceeded size of \(maximumBufferSize) bytes, emptied it")
                        }
                    }
                }
                Logger.debug("Can't obtain string from xcodebuild stdout \(mergedData.count) bytes, will shift data (\(previouslyUnparsedData.currentValue().count) bytes) to the next stdout event")
                break
            }
            
            do {
                try xcodebuildLogParser.parse(string: string, testRunnerStream: testRunnerStream)
            } catch {
                Logger.warning("Failed to parse xcodebuild output: \(error). This error will be ignored.")
            }
        }
    }
}
