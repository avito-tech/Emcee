import Foundation
import Models
import QueueServer
import XCTest

final class WorkerDetailsHolderTests: XCTestCase {
    let worker = WorkerId(value: "worker")
    let workerDetailsHolder = WorkerDetailsHolderImpl()
    
    func test___when_empty() {
        XCTAssertEqual(workerDetailsHolder.knownPorts, [:])
    }
    
    func test() {
        workerDetailsHolder.update(workerId: worker, restPort: 42)
        
        XCTAssertEqual(workerDetailsHolder.knownPorts, [worker: 42])
    }
}
