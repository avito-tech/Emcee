@testable import DistDeployer
import Deployer
import Extensions
import Models
import ModelsTestHelpers
import PathLib
import ResourceLocationResolver
import TemporaryStuff
import XCTest

class DeployablesGeneratorTests: XCTestCase {
    lazy var generator = DeployablesGenerator(
        emceeVersion: "SomeVersion",
        remoteEmceeBinaryName: "Emcee"
    )
    
    override func setUp() {
        super.setUp()
        self.continueAfterFailure = false
    }
    
    func testEmceeIsPresent() throws {
        let deployables = try generator.deployables()
        guard deployables.count == 1, let emceeDeployable = deployables.first else {
            return XCTFail("Expected to have a single deployable item")
        }
        XCTAssertEqual(emceeDeployable.files.first?.source, AbsolutePath(ProcessInfo.processInfo.executablePath))
        XCTAssertEqual(emceeDeployable.files.first?.destination, RelativePath("Emcee_SomeVersion"))
    }
}
