import Foundation
import XCTest
@testable import LaunchdUtils

class LaunchdUtilsTests: XCTestCase {
    func testGeneratingPlist() throws {
        let job = LaunchdJob(
            label: "com.example.test",
            programArguments: ["/bin", "arg1", "arg2"],
            environmentVariables: ["ENV": "val"],
            workingDirectory: "~/",
            runAtLoad: true,
            disabled: true,
            standardOutPath: nil,
            standardErrorPath: nil,
            sockets: ["sock1": LaunchdSocket(
                socketType: .stream,
                socketPassive: .listen,
                socketNodeName: "localhost",
                socketServiceName: .port(4321))],
            inetdCompatibility: .enabledWithoutWait,
            sessionType: .background)
        let plist = LaunchdPlist(job: job)
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
    <key>Disabled</key>
    <true/>
    <key>EnvironmentVariables</key>
    <dict>
        <key>ENV</key>
        <string>val</string>
    </dict>
    <key>Label</key>
    <string>com.example.test</string>
    <key>LimitLoadToSessionType</key>
    <string>Background</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin</string>
        <string>arg1</string>
        <string>arg2</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>Sockets</key>
    <dict>
        <key>sock1</key>
        <dict>
            <key>SockNodeName</key>
            <string>localhost</string>
            <key>SockPassive</key>
            <true/>
            <key>SockServiceName</key>
            <integer>4321</integer>
            <key>SockType</key>
            <string>stream</string>
        </dict>
    </dict>
    <key>WorkingDirectory</key>
    <string>~/</string>
    <key>inetdCompatibility</key>
    <dict>
        <key>Wait</key>
        <false/>
    </dict>
</dict>
</plist>
"""
        XCTAssertEqual(
            string.components(separatedBy: .whitespacesAndNewlines).joined(),
            expectedString.components(separatedBy: .whitespacesAndNewlines).joined())
    }
}
