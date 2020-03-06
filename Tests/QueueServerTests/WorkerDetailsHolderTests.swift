import Foundation
import Models
import QueueServer
import XCTest

final class WorkerDetailsHolderTests: XCTestCase {
    let worker = WorkerId(value: "worker")
    let socketAddress = SocketAddress(host: "host", port: 42)
    let workerDetailsHolder = WorkerDetailsHolderImpl()
    
    func test___when_empty() {
        XCTAssertEqual(workerDetailsHolder.knownAddresses, [:])
    }
    
    func test() {
        workerDetailsHolder.update(workerId: worker, restAddress: socketAddress)
        
        XCTAssertEqual(workerDetailsHolder.knownAddresses, [worker: socketAddress])
    }
}
