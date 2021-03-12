import Foundation
import PortDeterminer
import QueueModels
import RESTInterfaces
import RESTMethods
import RemotePortDeterminer
import RequestSender
import RequestSenderTestHelpers
import SocketModels
import Swifter
import XCTest

final class RemoteQueuePortScannerTests: XCTestCase {
    lazy var requestSenderProvider = DefaultRequestSenderProvider(logger: .noOp)
    
    func test___scanning_ports_without_queue___returns_empty_result() throws {
        let scanner = RemoteQueuePortScanner(
            host: "localhost",
            logger: .noOp,
            portRange: 12000...12005,
            requestSenderProvider: requestSenderProvider
        )
        let result = scanner.queryPortAndQueueServerVersion(timeout: 10.0)
        XCTAssertEqual(result, [:])
    }
    
    func test___scanning_ports_with_queue___returns_port_to_version_result() throws {
        let expectedVersion = Version(value: "version")
        let server = HttpServer()
        server[RESTMethod.queueVersion.pathWithLeadingSlash] = { request in
            let data = try! JSONEncoder().encode(QueueVersionResponse.queueVersion(expectedVersion))
            return .raw(200, "OK", ["Content-Type": "application/json"]) {
                try! $0.write(data)
            }
        }
        try server.start(0, forceIPv4: false, priority: .default)
        let port = SocketModels.Port(value: try server.port())
        
        let scanner = RemoteQueuePortScanner(
            host: "localhost",
            logger: .noOp,
            portRange: port...port,
            requestSenderProvider: requestSenderProvider
        )
        let result = scanner.queryPortAndQueueServerVersion(timeout: 10.0)
        XCTAssertEqual(result, [port: expectedVersion])
    }
}
