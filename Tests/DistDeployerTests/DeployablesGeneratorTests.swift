@testable import DistDeployer
import Deployer
import Extensions
import Models
import ModelsTestHelpers
import PathLib
import ResourceLocationResolver
import TemporaryStuff
import Version
import XCTest

class DeployablesGeneratorTests: XCTestCase {
    let versionStringValue = "SomeVersion"
    lazy var versionProvider = FixedVersionProvider(value: versionStringValue)
    lazy var generator = DeployablesGenerator(
        emceeVersionProvider: versionProvider,
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
        XCTAssertEqual(emceeDeployable.files.first?.destination, RelativePath("Emcee_" + versionStringValue))
    }
}

class FixedVersionProvider: VersionProvider {
    let value: String

    public init(value: String) {
        self.value = value
    }
    
    public func version() throws -> Version {
        return Version(value: value)
    }
}
