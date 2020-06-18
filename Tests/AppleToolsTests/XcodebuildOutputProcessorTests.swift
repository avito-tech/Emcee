import AppleTools
import Foundation
import Models
import RunnerTestHelpers
import XCTest

final class XcodebuildOutputProcessorTests: XCTestCase {
    lazy var testRunnerStream = AccumulatingTestRunnerStream()
    lazy var xcodebuildLogParser = FakeXcodebuildLogParser(
        testRunnerStream: testRunnerStream
    )
    lazy var xcodebuildOutputProcessor = XcodebuildOutputProcessor(
        testRunnerStream: testRunnerStream,
        xcodebuildLogParser: xcodebuildLogParser
    )
    
    func test___simple_processing() {
        testRunnerStream.streamIsOpen = false
        
        xcodebuildLogParser.onEvent = { string, stream in
            if string == "aaa" {
                stream.openStream()
            }
        }
        
        xcodebuildOutputProcessor.newStdout(data: "aaa".data(using: .utf8)!)
        
        XCTAssertTrue(testRunnerStream.streamIsOpen)
    }
    
    func test___processing_complex_data() {
        testRunnerStream.streamIsOpen = false
        
        let проверкаData = Data([
            0xD0, 0x9F, 0xD1, 0x80, 0xD0, 0xBE, 0xD0, 0xB2, 0xD0, 0xB5, 0xD1, 0x80, 0xD0, 0xBA, 0xD0, 0xB0
        ])
        
        xcodebuildLogParser.onEvent = { string, stream in
            if string == "Проверка" {
                stream.openStream()
            }
        }
        
        xcodebuildOutputProcessor.newStdout(data: проверкаData)
        
        XCTAssertTrue(testRunnerStream.streamIsOpen)
    }
    
    func test___processing_partial_data() {
        testRunnerStream.streamIsOpen = false
        
        let проверкаData = Data([
            0xD0, 0x9F, 0xD1, 0x80, 0xD0, 0xBE, 0xD0, 0xB2, 0xD0, 0xB5, 0xD1, 0x80, 0xD0, 0xBA, 0xD0, 0xB0
        ])
        
        xcodebuildLogParser.onEvent = { string, stream in
            if string == "Проверка" {
                stream.openStream()
            }
            if string == "close" {
                stream.closeStream()
            }
        }
        
        xcodebuildOutputProcessor.newStdout(data: проверкаData.dropLast())
        XCTAssertFalse(testRunnerStream.streamIsOpen)
        xcodebuildOutputProcessor.newStdout(data: проверкаData.dropFirst(проверкаData.count - 1))
        XCTAssertTrue(testRunnerStream.streamIsOpen)
        
        xcodebuildOutputProcessor.newStdout(data: "close".data(using: .utf8)!)
        XCTAssertFalse(testRunnerStream.streamIsOpen)
    }
    
    func test___processing_partial_data_chunks() {
        testRunnerStream.streamIsOpen = false
        
        xcodebuildLogParser.onEvent = { string, stream in
            if string == "Проверка" {
                stream.openStream()
            }
            if string == "close" {
                stream.closeStream()
            }
        }
        
        xcodebuildOutputProcessor.newStdout(data: Data([0xD0, 0x9F, 0xD1]))
        XCTAssertFalse(testRunnerStream.streamIsOpen)
        xcodebuildOutputProcessor.newStdout(data: Data([0x80, 0xD0]))
        XCTAssertFalse(testRunnerStream.streamIsOpen)
        xcodebuildOutputProcessor.newStdout(data: Data([0xBE, 0xD0, 0xB2, 0xD0, 0xB5, 0xD1]))
        XCTAssertFalse(testRunnerStream.streamIsOpen)
        xcodebuildOutputProcessor.newStdout(data: Data([0x80, 0xD0, 0xBA, 0xD0, 0xB0]))
        XCTAssertTrue(testRunnerStream.streamIsOpen)
        
        xcodebuildOutputProcessor.newStdout(data: "close".data(using: .utf8)!)
        XCTAssertFalse(testRunnerStream.streamIsOpen)
    }
}
