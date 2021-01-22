import Foundation
import JSONStream
import XCTest

class BlockingArrayBasedJSONStreamTests: XCTestCase {
    func testReadBlocksUntilNewDataComes() {
        let readQueue = OperationQueue()
        let writeQeuue = OperationQueue()
        let stream = BlockingArrayBasedJSONStream()
        stream.append(string: "1")
        
        var byte: UInt8?
        readQueue.addOperation {
            byte = stream.read()
            // next call will block until writeQueue updates the stream with new data
            byte = stream.read()
        }
        
        writeQeuue.addOperation {
            Thread.sleep(forTimeInterval: 0.3)
            stream.append(string: "2")
        }
        
        readQueue.waitUntilAllOperationsAreFinished()
        writeQeuue.waitUntilAllOperationsAreFinished()
        
        XCTAssertEqual(byte, 0x32)
    }
    
    func testReadBlocksUntilFlagFlips() {
        let readQueue = OperationQueue()
        let writeQeuue = OperationQueue()
        let stream = BlockingArrayBasedJSONStream()
        stream.append(string: "1")
        
        var byte: UInt8?
        readQueue.addOperation {
            byte = stream.read()  // == 1
            // next call will block until writeQueue flips the flag that data is over
            byte = stream.read()
        }
        
        writeQeuue.addOperation {
            Thread.sleep(forTimeInterval: 0.3)
            stream.close()
        }
        
        readQueue.waitUntilAllOperationsAreFinished()
        writeQeuue.waitUntilAllOperationsAreFinished()
        
        XCTAssertNil(byte)
    }
    
    func testReadBlocksMultipleThreadsUntilNewDataComes() {
        let readQueue1 = OperationQueue()
        let readQueue2 = OperationQueue()
        let writeQeuue = OperationQueue()
        let stream = BlockingArrayBasedJSONStream()
        
        var byte1: UInt8?
        var byte2: UInt8?
        
        readQueue1.addOperation { byte1 = stream.read() }
        readQueue2.addOperation { byte2 = stream.read() }
        
        writeQeuue.addOperation {
            Thread.sleep(forTimeInterval: 0.3)
            stream.append(string: "12")
        }
        
        readQueue1.waitUntilAllOperationsAreFinished()
        readQueue2.waitUntilAllOperationsAreFinished()
        writeQeuue.waitUntilAllOperationsAreFinished()
        
        // both byte1 and byte2 might have "1" or "2" values depending on the order of execution of the operations
        XCTAssertNotNil(byte1)
        XCTAssertNotNil(byte2)
        XCTAssertNotEqual(byte1, byte2)
    }
}
