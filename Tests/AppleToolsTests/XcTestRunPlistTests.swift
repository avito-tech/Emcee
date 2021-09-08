import AppleTools
import Foundation
import XCTest

final class XcTestRunPlistTests: XCTestCase {
    func test___creating() throws {
        let testRun = XcTestRun(
            testTargetName: "TestTargetName",
            bundleIdentifiersForCrashReportEmphasis: [
                "bundle.id.for.crash.report.1",
                "bundle.id.for.crash.report.2"
            ],
            dependentProductPaths: [
                "/path/1",
                "/path/2"
            ],
            testBundlePath: "/test/bundle/path",
            testHostPath: "/test/host/path",
            testHostBundleIdentifier: "test.host.bundle.id",
            uiTargetAppPath: "ui.target.app.path",
            environmentVariables: ["ENV": "VALUE"],
            commandLineArguments: ["cli", "args"],
            uiTargetAppEnvironmentVariables: ["UI_TARGET_APP_ENV": "VAL"],
            uiTargetAppCommandLineArguments: ["cli", "ui", "args"],
            uiTargetAppMainThreadCheckerEnabled: false,
            skipTestIdentifiers: ["tests", "to", "skip"],
            onlyTestIdentifiers: ["tests", "to", "run"],
            testingEnvironmentVariables: ["TESTING_ENV": "VAL"],
            isUITestBundle: true,
            isAppHostedTestBundle: false,
            isXCTRunnerHostedTestBundle: true,
            testTargetProductModuleName: "TestModuleName",
            systemAttachmentLifetime: .deleteOnSuccess,
            userAttachmentLifetime: .deleteOnSuccess
        )
        let plist = XcTestRunPlist(xcTestRun: testRun)
        let contents = try plist.createPlistData()

        guard let string = String(data: contents, encoding: .utf8) else {
            XCTFail("Unable to convert plist data to string")
            return
        }

        let expectedString = """
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>TestTargetName</key>
    <dict>
        <key>BundleIdentifiersForCrashReportEmphasis</key>
        <array>
            <string>bundle.id.for.crash.report.1</string>
            <string>bundle.id.for.crash.report.2</string>
        </array>
        <key>CommandLineArguments</key>
        <array>
            <string>cli</string>
            <string>args</string>
        </array>
        <key>DependentProductPaths</key>
        <array>
            <string>/path/1</string>
            <string>/path/2</string>
        </array>
        <key>EnvironmentVariables</key>
        <dict>
            <key>ENV</key>
            <string>VALUE</string>
        </dict>
        <key>IsAppHostedTestBundle</key>
        <false/>
        <key>IsUITestBundle</key>
        <true/>
        <key>IsXCTRunnerHostedTestBundle</key>
        <true/>
        <key>OnlyTestIdentifiers</key>
        <array>
            <string>tests</string>
            <string>to</string>
            <string>run</string>
        </array>
        <key>ProductModuleName</key>
        <string>TestModuleName</string>
        <key>SkipTestIdentifiers</key>
        <array>
            <string>tests</string>
            <string>to</string>
            <string>skip</string>
        </array>
        <key>SystemAttachmentLifetime</key>
        <string>deleteOnSuccess</string>
        <key>TestBundlePath</key>
        <string>/test/bundle/path</string>
        <key>TestHostBundleIdentifier</key>
        <string>test.host.bundle.id</string>
        <key>TestHostPath</key>
        <string>/test/host/path</string>
        <key>TestingEnvironmentVariables</key>
        <dict>
            <key>TESTING_ENV</key>
            <string>VAL</string>
        </dict>
        <key>UITargetAppCommandLineArguments</key>
        <array>
            <string>cli</string>
            <string>ui</string>
            <string>args</string>
        </array>
        <key>UITargetAppEnvironmentVariables</key>
        <dict>
            <key>UI_TARGET_APP_ENV</key>
            <string>VAL</string>
        </dict>
        <key>UITargetAppMainThreadCheckerEnabled</key>
        <false/>
        <key>UITargetAppPath</key>
        <string>ui.target.app.path</string>
        <key>UserAttachmentLifetime</key>
        <string>deleteOnSuccess</string>
    </dict>
</dict>
</plist>
"""
        XCTAssertEqual(
            string.components(separatedBy: .whitespacesAndNewlines).joined(),
            expectedString.components(separatedBy: .whitespacesAndNewlines).joined()
        )
    }
    
    func test___reading() throws {
        let testRun = XcTestRun(
            testTargetName: "TestTargetName",
            bundleIdentifiersForCrashReportEmphasis: [
                "bundle.id.for.crash.report.1",
                "bundle.id.for.crash.report.2"
            ],
            dependentProductPaths: [
                "/path/1",
                "/path/2"
            ],
            testBundlePath: "/test/bundle/path",
            testHostPath: "/test/host/path",
            testHostBundleIdentifier: "test.host.bundle.id",
            uiTargetAppPath: "ui.target.app.path",
            environmentVariables: ["ENV": "VALUE"],
            commandLineArguments: ["cli", "args"],
            uiTargetAppEnvironmentVariables: ["UI_TARGET_APP_ENV": "VAL"],
            uiTargetAppCommandLineArguments: ["cli", "ui", "args"],
            uiTargetAppMainThreadCheckerEnabled: false,
            skipTestIdentifiers: ["tests", "to", "skip"],
            onlyTestIdentifiers: ["tests", "to", "run"],
            testingEnvironmentVariables: ["TESTING_ENV": "VAL"],
            isUITestBundle: true,
            isAppHostedTestBundle: false,
            isXCTRunnerHostedTestBundle: true,
            testTargetProductModuleName: "TestModuleName",
            systemAttachmentLifetime: .deleteOnSuccess,
            userAttachmentLifetime: .deleteOnSuccess
        )
        let plist = XcTestRunPlist(xcTestRun: testRun)
        
        let parsedPlist = try XcTestRunPlist.readPlist(
            data: try plist.createPlistData()
        )
        
        XCTAssertEqual(
            testRun,
            parsedPlist.xcTestRun
        )
    }
}
