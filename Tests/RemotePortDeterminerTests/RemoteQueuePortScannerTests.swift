import Foundation
import Models
import PortDeterminer
import RemotePortDeterminer
import RESTMethods
import RequestSender
import RequestSenderTestHelpers
import Swifter
import Version
import XCTest

final class RemoteQueuePortScannerTests: XCTestCase {
    lazy var requestSenderProvider = DefaultRequestSenderProvider()
    
    func test___scanning_ports_without_queue___returns_empty_result() throws {
        let scanner = RemoteQueuePortScanner(
            host: "localhost",
            portRange: 12000...12005,
            requestSenderProvider: requestSenderProvider
        )
        let result = scanner.queryPortAndQueueServerVersion(timeout: 10.0)
        XCTAssertEqual(result, [:])
    }
    
    func test___scanning_ports_with_queue___returns_port_to_version_result() throws {
        let expectedVersion = Version(value: "version")
        let server = HttpServer()
        server[RESTMethod.queueVersion.withPrependingSlash] = { request in
            let data = try! JSONEncoder().encode(QueueVersionResponse.queueVersion(expectedVersion))
            return .raw(200, "OK", ["Content-Type": "application/json"]) {
                try! $0.write(data)
            }
        }
        try server.start(0, forceIPv4: false, priority: .default)
        let port = try server.port()
        
        let scanner = RemoteQueuePortScanner(
            host: "localhost",
            portRange: port...port,
            requestSenderProvider: requestSenderProvider
        )
        let result = scanner.queryPortAndQueueServerVersion(timeout: 10.0)
        XCTAssertEqual(result, [port: expectedVersion])
    }
}
