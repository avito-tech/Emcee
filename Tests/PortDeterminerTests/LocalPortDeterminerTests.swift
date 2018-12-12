import Foundation
import PortDeterminer
import Swifter
import XCTest

final class LocalPortDeterminerTests: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }
    
    func test___if_port_range_is_busy___determiner_throws() {
        let server = busyServerWithPort()
        let port = server.port
        
        let determiner = LocalPortDeterminer(portRange: port...port)
        XCTAssertThrowsError(_ = try determiner.availableLocalPort())
    }
    
    func test___if_port_range_has_free_port___determiner_returns_available_port() {
        let port = freePort()
        
        let determiner = LocalPortDeterminer(portRange: port...port)
        XCTAssertNoThrow(
            XCTAssertEqual(try determiner.availableLocalPort(), port)
        )
    }
    
    func test___if_port_range_has_some_free_ports_among_busy___determiner_returns_available_port() {
        let server = busyServerWithPort()
        let freePort = self.freePort()
        
        // this could be flaky, as we can't guarantee that we will have continuous port range
        if server.port == freePort - 1 {
            let determiner = LocalPortDeterminer(portRange: server.port...freePort)
            XCTAssertNoThrow(
                XCTAssertEqual(try determiner.availableLocalPort(), freePort)
            )
        }
    }
    
    private func busyServerWithPort(file: StaticString = #file, line: UInt = #line) -> (server: HttpServer, port: Int) {
        let httpServer = HttpServer()
        XCTAssertNoThrow(
            try httpServer.start(0, forceIPv4: false, priority: .background),
            file: file,
            line: line
        )
        return (server: httpServer, port: try! httpServer.port())
    }
    
    private func freePort(file: StaticString = #file, line: UInt = #line) -> Int {
        let temporaryHttpServer = HttpServer()
        XCTAssertNoThrow(
            try temporaryHttpServer.start(0, forceIPv4: false, priority: .background),
            file: file,
            line: line
        )
        let port = try! temporaryHttpServer.port()
        temporaryHttpServer.stop()
        return port
    }
}
