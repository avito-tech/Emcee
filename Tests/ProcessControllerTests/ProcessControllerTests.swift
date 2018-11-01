import Basic
import Extensions
import Foundation
import ProcessController
import XCTest

final class ProcessControllerTests: XCTestCase {
    func testStartingSimpleSubprocess() throws {
        let controller = try ProcessController(subprocess: Subprocess(arguments: ["/usr/bin/env"]))
        controller.startAndListenUntilProcessDies()
        XCTAssertEqual(controller.terminationStatus(), 0)
    }
    
    func testSilence() throws {
        let controller = try ProcessController(
            subprocess: Subprocess(
                arguments: ["/bin/sleep", "10"],
                maximumAllowedSilenceDuration: 0.01))
        let delegate = FakeDelegate()
        controller.delegate = delegate
        controller.startAndListenUntilProcessDies()
        
        XCTAssertEqual(delegate.noActivityDetected, true)
    }
    
    func testWhenSubprocessFinishesSilenceIsNotReported() throws {
        let controller = try ProcessController(
            subprocess: Subprocess(
                arguments: ["/bin/sleep"],
                maximumAllowedSilenceDuration: 1.0))
        let delegate = FakeDelegate()
        controller.delegate = delegate
        controller.startAndListenUntilProcessDies()
        
        XCTAssertEqual(delegate.noActivityDetected, false)
    }
    
    func testGettingStdout() throws {
        let tempFile = try TemporaryFile()
        
        let controller = try ProcessController(
            subprocess: Subprocess(
                arguments: ["/bin/ls", "/"],
                stdoutContentsFile: tempFile.path.asString))
        controller.startAndListenUntilProcessDies()
        
        let data = try Data(contentsOf: URL(fileURLWithPath: tempFile.path.asString))
        guard let string = String(data: data, encoding: .utf8) else {
            XCTFail("Unable to get stdout string")
            return
        }
        XCTAssertTrue(string.contains("Applications"))
    }
    
    func testGettingStderr() throws {
        let tempFile = try TemporaryFile()
        
        let argument = "/\(UUID().uuidString)"
        let controller = try ProcessController(
            subprocess: Subprocess(
                arguments: ["/bin/ls", argument],
                stderrContentsFile: tempFile.path.asString))
        controller.startAndListenUntilProcessDies()
        
        let data = try Data(contentsOf: URL(fileURLWithPath: tempFile.path.asString))
        guard let string = String(data: data, encoding: .utf8) else {
            XCTFail("Unable to get stderr string")
            return
        }
        XCTAssertEqual(
            string.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines),
            "ls: \(argument): No such file or directory")
    }
    
    func testGettingStdoutAndStderr() throws {
        let stdoutFile = try TemporaryFile()
        let stderrFile = try TemporaryFile()
        
        let argument = "/\(UUID().uuidString)"
        let controller = try ProcessController(
            subprocess: Subprocess(
                arguments: ["/bin/ls", "/", argument],
                stdoutContentsFile: stdoutFile.path.asString,
                stderrContentsFile: stderrFile.path.asString))
        controller.startAndListenUntilProcessDies()
        
        let stdoutData = try Data(contentsOf: URL(fileURLWithPath: stdoutFile.path.asString))
        guard let stdoutString = String(data: stdoutData, encoding: .utf8) else {
            XCTFail("Unable to get stdout string")
            return
        }
        
        let stderrData = try Data(contentsOf: URL(fileURLWithPath: stderrFile.path.asString))
        guard let stderrString = String(data: stderrData, encoding: .utf8) else {
            XCTFail("Unable to get stdin string")
            return
        }
        
        XCTAssertTrue(stdoutString.contains("Applications"))
        XCTAssertTrue(stderrString.contains("ls: \(argument): No such file or directory"))
    }
    
    func testWritingToStdin() throws {
        let stdoutFile = try TemporaryFile()
        let stderrFile = try TemporaryFile()
        let stdinFile = try TemporaryFile()
        let streamingSwiftTempFile = try TemporaryFile()
        let streamingSwiftFile = #file.deletingLastPathComponent.appending(pathComponent: "StdInToStdOutStreamer.swift")
        var swiftTestCode = try String(contentsOfFile: streamingSwiftFile)
        swiftTestCode = swiftTestCode.replacingOccurrences(of: "//uncomment_from_tests", with: "")
        streamingSwiftTempFile.fileHandle.write(swiftTestCode)
        
        let controller = try ProcessController(
            subprocess: Subprocess(
                arguments: ["/usr/bin/swift", streamingSwiftTempFile.path.asString],
                maximumAllowedSilenceDuration: 10,
                allowedTimeToConsumeStdin: 20,
                stdoutContentsFile: stdoutFile.path.asString,
                stderrContentsFile: stderrFile.path.asString,
                stdinContentsFile: stdinFile.path.asString))
        let delegate = FakeDelegate()
        controller.delegate = delegate
        controller.start()
        
        try controller.writeToStdIn(data: "hello, this is first stdin data!".data(using: .utf8)!)
        try controller.writeToStdIn(data: "hello, this is second stdin data!\n".data(using: .utf8)!)
        try controller.writeToStdIn(data: "bye".data(using: .utf8)!)
        controller.waitForProcessToDie()
        
        let stdoutData = try Data(contentsOf: URL(fileURLWithPath: stdoutFile.path.asString))
        guard let stdoutString = String(data: stdoutData, encoding: .utf8) else {
            XCTFail("Unable to get stdout string")
            return
        }
        
        let stdinData = try Data(contentsOf: URL(fileURLWithPath: stdinFile.path.asString))
        guard let stdinString = String(data: stdinData, encoding: .utf8) else {
            XCTFail("Unable to get stdin string")
            return
        }
        
        XCTAssertTrue(stdinString.contains("hello, this is first stdin data!"))
        XCTAssertTrue(stdinString.contains("hello, this is second stdin data!"))
        
        XCTAssertTrue(stdoutString.contains("stdin-to-stdout-streamer started!"))
        XCTAssertTrue(stdoutString.contains("stdin: "))
        XCTAssertTrue(stdoutString.contains("hello, this is first stdin data!"))
        XCTAssertTrue(stdoutString.contains("hello, this is second stdin data!"))
    }
}
