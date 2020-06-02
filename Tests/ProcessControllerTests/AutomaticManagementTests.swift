import Foundation
import ProcessController
import SignalHandling
import XCTest

final class AutomaticManagementTests: XCTestCase {
    func test___silent() {
        XCTAssertEqual(
            AutomaticManagement.sigintThenKillIfSilent(interval: 42, killAfter: 20),
            AutomaticManagement(
                items: [
                    .signalWhenSilent(.int, 42),
                    .signalWhenSilent(.kill, 62)
                ]
            )
        )
        
        XCTAssertEqual(
            AutomaticManagement.sigtermThenKillIfSilent(interval: 42, killAfter: 20),
            AutomaticManagement(
                items: [
                    .signalWhenSilent(.term, 42),
                    .signalWhenSilent(.kill, 62)
                ]
            )
        )
    }
    
    func test___timeout() {
        XCTAssertEqual(
            AutomaticManagement.sigintThenKillAfterRunningFor(interval: 42, killAfter: 20),
            AutomaticManagement(
                items: [
                    .signalAfter(.int, 42),
                    .signalAfter(.kill, 62)
                ]
            )
        )
        
        XCTAssertEqual(
            AutomaticManagement.sigtermThenKillAfterRunningFor(interval: 42, killAfter: 20),
            AutomaticManagement(
                items: [
                    .signalAfter(.term, 42),
                    .signalAfter(.kill, 62)
                ]
            )
        )
    }
    
    func test___no_management() {
        XCTAssertEqual(
            AutomaticManagement.noManagement,
            AutomaticManagement.multiple([])
        )
    }
}
