import Foundation
import PlistLib
import SimulatorPool
import SimulatorPoolModels
import SimulatorPoolTestHelpers
import Tmp
import TestDestinationTestHelpers
import TestHelpers
import XCTest

final class DefaultCoreSimulatorStateProviderTests: XCTestCase {
    lazy var provider = DefaultCoreSimulatorStateProvider()
    lazy var tempFolder = assertDoesNotThrow { try TemporaryFolder() }
    lazy var udid = UDID(value: "udid")
    lazy var simulator = Simulator(
        testDestination: TestDestinationFixtures.iOSTestDestination,
        udid: udid,
        path: tempFolder.absolutePath
    )
    
    func test___reading_state_from_plist() throws {
        let plist = Plist(rootPlistEntry: .dict(["state": .number(1)]))
        try tempFolder.createFile(filename: "device.plist", contents: plist.data(format: .xml))
        
        let state = try provider.coreSimulatorState(
            simulator: simulator
        )
        XCTAssertEqual(state, .shutdown)
    }
    
    func test___state_from_non_existing_plist___nil() throws {
        let state = try provider.coreSimulatorState(
            simulator: simulator
        )
        XCTAssertNil(state)
    }
}
