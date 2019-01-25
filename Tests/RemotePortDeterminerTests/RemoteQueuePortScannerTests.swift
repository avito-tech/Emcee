import Foundation
import Models
import PortDeterminer
import RemotePortDeterminer
import RESTMethods
import Swifter
import Version
import XCTest

final class RemoteQueuePortScannerTests: XCTestCase {
    let localPortDeterminer = LocalPortDeterminer(portRange: Ports.defaultQueuePortRange)
    
    func test___scanning_ports_without_queue___returns_empty_result() {
        let scanner = RemoteQueuePortScanner(host: "localhost", portRange: 12000...12005)
        let result = scanner.queryPortAndQueueServerVersion()
        XCTAssertEqual(result, [:])
    }
    
    func test___scanning_ports_with_queue___returns_port_to_version_result() throws {
        let expectedVersion = Version(stringValue: "version")
        let server = HttpServer()
        server[RESTMethod.queueVersion.withPrependingSlash] = { request in
            let data = try! JSONEncoder().encode(QueueVersionResponse.queueVersion(expectedVersion))
            return .raw(200, "OK", ["Content-Type": "application/json"]) {
                try! $0.write(data)
            }
        }
        try server.start(0, forceIPv4: false, priority: .default)
        let port = try server.port()
        
        let scanner = RemoteQueuePortScanner(host: "localhost", portRange: port...port)
        let result = scanner.queryPortAndQueueServerVersion()
        XCTAssertEqual(result, [port: expectedVersion])
    }
    
    
}
