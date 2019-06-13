import Foundation
import SimulatorPool
import XCTest

final class SimulatorStateMachineTests: XCTestCase {
    let machine = SimulatorStateMachine()
    
    /// MARK: Switching from Absent
    
    func test___absent_to_created___action_empty() {
        XCTAssertEqual(
            machine.actionsToSwitchStates(sourceState: .absent, targetState: .absent),
            []
        )
    }
    
    func test___absent_to_created___action_is_create() {
        XCTAssertEqual(
            machine.actionsToSwitchStates(sourceState: .absent, targetState: .created),
            [.create]
        )
    }
    
    func test___absent_to_booted___action_is_create_boot() {
        XCTAssertEqual(
            machine.actionsToSwitchStates(sourceState: .absent, targetState: .booted),
            [.create, .boot]
        )
    }
    
    /// MARK: Switching from Created
    
    func test___created_to_created___action_is_empty() {
        XCTAssertEqual(
            machine.actionsToSwitchStates(sourceState: .created, targetState: .created),
            []
        )
    }
    
    func test___created_to_absent___action_is_delete() {
        XCTAssertEqual(
            machine.actionsToSwitchStates(sourceState: .created, targetState: .absent),
            [.delete]
        )
    }
    
    func test___created_to_booted___action_is_boot() {
        XCTAssertEqual(
            machine.actionsToSwitchStates(sourceState: .created, targetState: .booted),
            [.boot]
        )
    }
    
    /// MARK: Switching from Booted
    
    func test___booted_to_booted___action_is_empty() {
        XCTAssertEqual(
            machine.actionsToSwitchStates(sourceState: .booted, targetState: .booted),
            []
        )
    }
    
    func test___booted_to_absent___action_is_shudown_delete() {
        XCTAssertEqual(
            machine.actionsToSwitchStates(sourceState: .booted, targetState: .absent),
            [.shutdown, .delete]
        )
    }
    
    func test___booted_to_created___action_is_shutdown() {
        XCTAssertEqual(
            machine.actionsToSwitchStates(sourceState: .booted, targetState: .created),
            [.shutdown]
        )
    }
    
    /// MARK: - Closest State
    
    func test___created_to_absent_or_created___action_is_empty() {
        XCTAssertEqual(
            machine.actionsToSwitchStates(sourceState: .created, closestStateFrom: [.absent, .created]),
            []
        )
    }
    
    func test___absent_to_created_or_booted___action_is_create() {
        XCTAssertEqual(
            machine.actionsToSwitchStates(sourceState: .absent, closestStateFrom: [.created, .booted]),
            [.create]
        )
    }
}
