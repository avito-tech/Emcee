import Foundation
import JSONStream
import XCTest

class BlockingArrayBasedJSONStreamTests: XCTestCase {
    func testReadBlocksUntilNewDataComes() {
        let readQueue = OperationQueue()
        let writeQeuue = OperationQueue()
        let stream = BlockingArrayBasedJSONStream()
        stream.append(scalars: ["1"])
        
        var scalar: Unicode.Scalar?
        readQueue.addOperation {
            scalar = stream.read()
            // next call will block until writeQueue updates the stream with new data
            scalar = stream.read()
        }
        
        writeQeuue.addOperation {
            Thread.sleep(forTimeInterval: 0.3)
            stream.append(scalars: ["2"])
        }
        
        readQueue.waitUntilAllOperationsAreFinished()
        writeQeuue.waitUntilAllOperationsAreFinished()
        
        XCTAssertEqual(scalar, "2")
    }
    
    func testReadBlocksUntilFlagFlips() {
        let readQueue = OperationQueue()
        let writeQeuue = OperationQueue()
        let stream = BlockingArrayBasedJSONStream()
        stream.append(scalars: ["1"])
        
        var scalar: Unicode.Scalar?
        readQueue.addOperation {
            scalar = stream.read()  // == 1
            // next call will block until writeQueue flips the flag that data is over
            scalar = stream.read()
        }
        
        writeQeuue.addOperation {
            Thread.sleep(forTimeInterval: 0.3)
            stream.close()
        }
        
        readQueue.waitUntilAllOperationsAreFinished()
        writeQeuue.waitUntilAllOperationsAreFinished()
        
        XCTAssertNil(scalar)
    }
    
    func testReadBlocksMultipleThreadsUntilNewDataComes() {
        let readQueue1 = OperationQueue()
        let readQueue2 = OperationQueue()
        let writeQeuue = OperationQueue()
        let stream = BlockingArrayBasedJSONStream()
        
        var scalar1: Unicode.Scalar?
        var scalar2: Unicode.Scalar?
        
        readQueue1.addOperation { scalar1 = stream.read() }
        readQueue2.addOperation { scalar2 = stream.read() }
        
        writeQeuue.addOperation {
            Thread.sleep(forTimeInterval: 0.3)
            stream.append(scalars: ["1", "2"])
        }
        
        readQueue1.waitUntilAllOperationsAreFinished()
        readQueue2.waitUntilAllOperationsAreFinished()
        writeQeuue.waitUntilAllOperationsAreFinished()
        
        // both scalar1 and scalar2 might have "1" or "2" values depending on the order of execution of the operations
        XCTAssertNotNil(scalar1)
        XCTAssertNotNil(scalar2)
        XCTAssertNotEqual(scalar1, scalar2)
    }
}
