@testable import Deployer
import Extensions
import Foundation
import PathLib
import XCTest

class DeployableBundleTests: XCTestCase {
    func testBundle() throws {
        let bundle = Bundle(for: DeployableBundleTests.self)
        let deployableBundle = try DeployableBundle(name: "MyBundle", bundlePath: AbsolutePath(bundle.bundlePath))
        
        let plistFiles = deployableBundle.files.filter { file -> Bool in
            // Xcode builds separate xctest bundle while Swift PM merges all tests into a single binary
            // Luckily it has DSYM file with Plist - we use this as an indicator
            // Since we are preparing a deployable bundle with its contents, it will have Info.plist file in both cases
            // TODO: rewrite and use custom made hierarchy of files, remove `Bundle(for:)`
            file.destination == RelativePath("\(bundle.bundleURL.lastPathComponent)/Contents/Info.plist") ||
                file.destination.pathString.hasSuffix(".dSYM/Contents/Info.plist")
        }
        XCTAssertEqual(plistFiles.count, 1)
    }
}
