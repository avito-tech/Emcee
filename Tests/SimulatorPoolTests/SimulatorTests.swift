@testable import SimulatorPool
import Models
import XCTest
import PathLib
import TemporaryStuff

class SimulatorTests: XCTestCase {
    
    var tempFolder: TemporaryFolder!
    var simulator: Simulator!
    var home: String!
    var testDestination: TestDestination!
    
    let uuid = UDID("C7AFD056-F6BB-4F30-A0C6-B17810EA4B53")
    
    override func setUp() {
        if let home = ProcessInfo.processInfo.environment["HOME"] {
            self.home = home
        } else {
            XCTFail("No HOME environment")
        }
        
        XCTAssertNoThrow(try {
            testDestination = try TestDestination(deviceType: "iPhone X", runtime: "iOS 12.1")
            tempFolder = try TemporaryFolder()
            
            _ = try tempFolder.pathByCreatingDirectories(
                components: [
                    "sim",
                    uuid.value
                ]
            )
            
            simulator = Simulator(
                testDestination: testDestination,
                workingDirectory: tempFolder.absolutePath
            )
        }())
    }
    
    func test___uuid() throws {
        XCTAssertEqual(simulator.uuid, uuid)
    }
    
    func test___simulatorSetContainerPath() throws {
        XCTAssertEqual(
            simulator.simulatorSetContainerPath,
            AbsolutePath("\(tempFolder.absolutePath.pathString)/sim")
        )
    }
    
    func test___identifier() throws {
        XCTAssertEqual(
            simulator.identifier,
            "simulator_iPhoneX_iOS12.1"
        )
    }
}
