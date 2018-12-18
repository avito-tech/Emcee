import BalancingBucketQueue
import EventBus
import Foundation
import Models
import PortDeterminer
import QueueClient
import QueueServer
import XCTest

final class RemotePortDeterminerTests: XCTestCase {
    let workerId = "workerId"
    let localPortDeterminer = LocalPortDeterminer(portRange: Ports.defaultQueuePortRange)
    
    func test___scanning_ports_without_queue___returns_empty_result() {
        let scanner = RemotePortDeterminer(host: "localhost", portRange: 12000...12005, workerId: workerId)
        let result = scanner.queryPortAndQueueServerVersion()
        XCTAssertEqual(result, [:])
    }
    
    func test___scanning_ports_with_queue___returns_port_to_version_result() throws {
        let server = QueueServer(
            eventBus: EventBus(),
            workerConfigurations: WorkerConfigurations(),
            reportAliveInterval: .infinity,
            numberOfRetries: 0,
            newWorkerRegistrationTimeAllowance: 0.0,
            checkAgainTimeInterval: .infinity,
            localPortDeterminer: localPortDeterminer,
            nothingToDequeueBehavior: NothingToDequeueBehaviorWaitForAllQueuesToDeplete(checkAfter: 42)
        )
        let port = try server.start()
        
        let scanner = RemotePortDeterminer(host: "localhost", portRange: port...port, workerId: workerId)
        let result = scanner.queryPortAndQueueServerVersion()
        XCTAssertEqual(result, [port: try server.version()])
    }
    
    
}
