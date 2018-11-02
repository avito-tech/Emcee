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

        let controller = try controllerForCommandLineTestExecutableTool(
            stdoutFile: stdoutFile.path,
            stderrFile: stderrFile.path,
            stdinFile: stdinFile.path)
        
        try controller.writeToStdIn(data: "hello, this is first stdin data!".data(using: .utf8)!)
        try controller.writeToStdIn(data: "hello, this is second stdin data!".data(using: .utf8)!)
        try controller.writeToStdIn(data: "bye".data(using: .utf8)!)
        controller.waitForProcessToDie()
        
        let stdoutString = try fileContents(path: stdoutFile.path)
        let stdinString = try fileContents(path: stdinFile.path)
        
        XCTAssertEqual(
            stdinString,
            "hello, this is first stdin data!"
                + "hello, this is second stdin data!"
                + "bye")
        XCTAssertEqual(
            stdoutString,
            "stdin-to-stdout-streamer started!"
                + "hello, this is first stdin data!"
                + "hello, this is second stdin data!"
                + "bye")
    }
    
    func testWritingHugeData() throws {
        let stdoutFile = try TemporaryFile()
        let stderrFile = try TemporaryFile()
        let stdinFile = try TemporaryFile()
        
        let controller = try controllerForCommandLineTestExecutableTool(
            stdoutFile: stdoutFile.path,
            stderrFile: stderrFile.path,
            stdinFile: stdinFile.path)
        
        let inputString = Array(repeating: "qwertyuiop", count: 1000000).joined()
        
        try controller.writeToStdIn(data: inputString.data(using: .utf8)!)
        try controller.writeToStdIn(data: "bye".data(using: .utf8)!)
        controller.waitForProcessToDie()
        
        let stdoutString = try fileContents(path: stdoutFile.path)
        let stdinString = try fileContents(path: stdinFile.path)
        
        XCTAssertEqual(
            stdinString,
            inputString + "bye")
        XCTAssertEqual(
            stdoutString,
            "stdin-to-stdout-streamer started!" + inputString + "bye")
    }
    
    private func fileContents(path: AbsolutePath) throws -> String {
        let dataata = try Data(contentsOf: URL(fileURLWithPath: path.asString))
        guard let contents = String(data: dataata, encoding: .utf8) else {
            fatalError("Unable to get contents of file: \(path)")
        }
        return contents
    }
    
    private func controllerForCommandLineTestExecutableTool(
        stdoutFile: AbsolutePath,
        stderrFile: AbsolutePath,
        stdinFile: AbsolutePath)
        throws -> ProcessController
    {
        let streamingSwiftTempFile = try TemporaryFile()
        let streamingSwiftFile = #file.deletingLastPathComponent.appending(pathComponent: "StdInToStdOutStreamer.swift")
        var swiftTestCode = try String(contentsOfFile: streamingSwiftFile)
        swiftTestCode = swiftTestCode.replacingOccurrences(of: "//uncomment_from_tests", with: "")
        streamingSwiftTempFile.fileHandle.write(swiftTestCode)
        
        let controller = try ProcessController(
            subprocess: Subprocess(
                arguments: ["/usr/bin/swift", streamingSwiftTempFile],
                maximumAllowedSilenceDuration: 10,
                stdoutContentsFile: stdoutFile.asString,
                stderrContentsFile: stderrFile.asString,
                stdinContentsFile: stdinFile.asString))
        let delegate = FakeDelegate()
        controller.delegate = delegate
        controller.start()
        return controller
    }
}

extension TemporaryFile: SubprocessArgument {
    public func stringValue() throws -> String {
        return path.asString
    }
}
