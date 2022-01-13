import Foundation
import QueueCommunication
import QueueModels
import SocketModels
import TestHelpers
import XCTest

final class WorkersPerQueueTests: XCTestCase {
    func test() {
        let workersPerQueue: WorkersPerQueue = [
            QueueInfo(
                queueAddress: SocketAddress(host: "host1", port: 42),
                queueVersion: "version"
            ): Set([
                WorkerId("worker1"),
                WorkerId("worker2"),
                WorkerId("worker3"),
            ]),
            QueueInfo(
                queueAddress: SocketAddress(host: "host2", port: 42),
                queueVersion: "version"
            ): Set([
                WorkerId("worker8"),
                WorkerId("worker4"),
                WorkerId("worker1"),
            ]),
        ]
        
        assert {
            "\(workersPerQueue)"
        } equals: {
            "version@host1:42: [\"worker1\", \"worker2\", \"worker3\"]; version@host2:42: [\"worker1\", \"worker4\", \"worker8\"]"
        }
    }
}
