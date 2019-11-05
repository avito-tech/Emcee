import Extensions
import Foundation
import PathLib
import ProcessController
import TemporaryStuff
import XCTest

final class DefaultProcessControllerTests: XCTestCase {
    func testStartingSimpleSubprocess() throws {
        let controller = try DefaultProcessController(subprocess: Subprocess(arguments: ["/usr/bin/env"]))
        controller.startAndListenUntilProcessDies()
        XCTAssertEqual(controller.processStatus(), .terminated(exitCode: 0))
    }
    
    func testSilence() throws {
        let controller = try DefaultProcessController(
            subprocess: Subprocess(
                arguments: ["/bin/sleep", "10"],
                silenceBehavior: SilenceBehavior(
                    automaticAction: .noAutomaticAction,
                    allowedSilenceDuration: 0.01
                )
            )
        )
        let delegate = FakeDelegate()
        controller.delegate = delegate
        controller.startAndListenUntilProcessDies()
        
        XCTAssertEqual(delegate.noActivityDetected, true)
    }
    
    func test___termination_status_is_running___when_process_is_running() throws {
        let controller = try DefaultProcessController(
            subprocess: Subprocess(
                arguments: ["/bin/sleep", "10"]
            )
        )
        controller.start()
        XCTAssertEqual(controller.processStatus(), .stillRunning)
    }
    
    func test___termination_status_is_not_started___when_process_has_not_yet_started() throws {
        let controller = try DefaultProcessController(
            subprocess: Subprocess(
                arguments: ["/bin/env"]
            )
        )
        XCTAssertEqual(controller.processStatus(), .notStarted)
    }
    
    func test___no_automatic_action() throws {
        let controller = try DefaultProcessController(
            subprocess: Subprocess(
                arguments: ["/bin/sleep", "0.01"],
                silenceBehavior: SilenceBehavior(
                    automaticAction: .noAutomaticAction,
                    allowedSilenceDuration: 0.00001
                )
            )
        )
        controller.startAndListenUntilProcessDies()
        XCTAssertEqual(controller.processStatus(), .terminated(exitCode: 0))
    }
    
    func test___silence_handler_action() throws {
        let handlerCalledExpectation = expectation(description: "silence handler has been called")
        
        let controller = try DefaultProcessController(
            subprocess: Subprocess(
                arguments: ["/bin/sleep", "999"],
                silenceBehavior: SilenceBehavior(
                    automaticAction: .handler({ sender in
                        kill(sender.processId, SIGKILL)
                        handlerCalledExpectation.fulfill()
                    }),
                    allowedSilenceDuration: 0.00001
                )
            )
        )
        controller.startAndListenUntilProcessDies()
        
        wait(for: [handlerCalledExpectation], timeout: 5.0)
    }
    
    func test___automatic_interrupt_silence_handler() throws {
        let controller = try DefaultProcessController(
            subprocess: Subprocess(
                arguments: ["/bin/sleep", "999"],
                silenceBehavior: SilenceBehavior(
                    automaticAction: .interruptAndForceKill,
                    allowedSilenceDuration: 0.00001
                )
            )
        )
        controller.startAndListenUntilProcessDies()
        XCTAssertEqual(controller.processStatus(), .terminated(exitCode: SIGINT))
    }
    
    func test___automatic_terminate_silence_handler() throws {
        let controller = try DefaultProcessController(
            subprocess: Subprocess(
                arguments: ["/bin/sleep", "999"],
                silenceBehavior: SilenceBehavior(
                    automaticAction: .terminateAndForceKill,
                    allowedSilenceDuration: 0.00001
                )
            )
        )
        controller.startAndListenUntilProcessDies()
        XCTAssertEqual(controller.processStatus(), .terminated(exitCode: SIGTERM))
    }
    
    func testWhenSubprocessFinishesSilenceIsNotReported() throws {
        let controller = try DefaultProcessController(
            subprocess: Subprocess(
                arguments: ["/bin/sleep"],
                silenceBehavior: SilenceBehavior(
                    automaticAction: .noAutomaticAction,
                    allowedSilenceDuration: 1.0
                )
            )
        )
        let delegate = FakeDelegate()
        controller.delegate = delegate
        controller.startAndListenUntilProcessDies()
        
        XCTAssertEqual(delegate.noActivityDetected, false)
    }
    
    func test__executing_from_specific_working_directory() throws {
        let temporaryFolder = try TemporaryFolder()
        
        let controller = try DefaultProcessController(
            subprocess: Subprocess(
                arguments: ["/bin/pwd"],
                workingDirectory: temporaryFolder.absolutePath
            )
        )
        controller.startAndListenUntilProcessDies()
        
        XCTAssertEqual(
            try String(contentsOfFile: controller.subprocess.standardStreamsCaptureConfig.stdoutContentsFile.pathString),
            temporaryFolder.absolutePath.pathString + "\n"
        )
    }
    
    func testGettingStdout() throws {
        let tempFile = try TemporaryFile()
        
        let controller = try DefaultProcessController(
            subprocess: Subprocess(
                arguments: ["/bin/ls", "/"],
                standardStreamsCaptureConfig: StandardStreamsCaptureConfig(
                    stdoutContentsFile: tempFile.absolutePath
                )
            )
        )
        controller.startAndListenUntilProcessDies()
        
        let data = try Data(contentsOf: URL(fileURLWithPath: tempFile.absolutePath.pathString))
        guard let string = String(data: data, encoding: .utf8) else {
            XCTFail("Unable to get stdout string")
            return
        }
        XCTAssertTrue(string.contains("Applications"))
    }
    
    func testGettingStderr() throws {
        let tempFile = try TemporaryFile()
        
        let argument = "/\(UUID().uuidString)"
        let controller = try DefaultProcessController(
            subprocess: Subprocess(
                arguments: ["/bin/ls", argument],
                standardStreamsCaptureConfig: StandardStreamsCaptureConfig(
                    stderrContentsFile: tempFile.absolutePath
                )
            )
        )
        controller.startAndListenUntilProcessDies()
        
        let data = try Data(contentsOf: tempFile.absolutePath.fileUrl)
        guard let string = String(data: data, encoding: .utf8) else {
            XCTFail("Unable to get stderr string")
            return
        }
        XCTAssertEqual(
            string,
            "ls: \(argument): No such file or directory\n"
        )
    }
    
    func testGettingStdoutAndStderr() throws {
        let stdoutFile = try TemporaryFile()
        let stderrFile = try TemporaryFile()
        
        let argument = "/\(UUID().uuidString)"
        let controller = try DefaultProcessController(
            subprocess: Subprocess(
                arguments: ["/bin/ls", "/", argument],
                standardStreamsCaptureConfig: StandardStreamsCaptureConfig(
                    stdoutContentsFile: stdoutFile.absolutePath,
                    stderrContentsFile: stderrFile.absolutePath
                )
            )
        )
        controller.startAndListenUntilProcessDies()
        
        let stdoutData = try Data(contentsOf: stdoutFile.absolutePath.fileUrl)
        guard let stdoutString = String(data: stdoutData, encoding: .utf8) else {
            XCTFail("Unable to get stdout string")
            return
        }
        
        let stderrData = try Data(contentsOf: stderrFile.absolutePath.fileUrl)
        guard let stderrString = String(data: stderrData, encoding: .utf8) else {
            XCTFail("Unable to get stdin string")
            return
        }
        
        XCTAssertTrue(stdoutString.contains("Applications"))
        XCTAssertTrue(stderrString.contains("ls: \(argument): No such file or directory"))
    }
    
    func test___stdout_listener() throws {
        let controller = try DefaultProcessController(
            subprocess: Subprocess(
                arguments: ["/bin/ls", "/bin/ls"]
            )
        )
        
        var stdoutData = Data()
        controller.onStdout { _, data, _ in stdoutData.append(contentsOf: data) }
        controller.startAndListenUntilProcessDies()
        
        guard let string = String(data: stdoutData, encoding: .utf8) else {
            return XCTFail("Unable to get stdout string")
        }
        XCTAssertEqual(string, "/bin/ls\n")
    }
    
    func test___stderr_listener() throws {
        let argument = UUID().uuidString + UUID().uuidString
        
        let controller = try DefaultProcessController(
            subprocess: Subprocess(
                arguments: ["/bin/ls", "/bin/" + argument]
            )
        )
        
        var stderrData = Data()
        controller.onStderr { _, data, _ in stderrData.append(contentsOf: data) }
        controller.startAndListenUntilProcessDies()
        
        guard let string = String(data: stderrData, encoding: .utf8) else {
            return XCTFail("Unable to get stdout string")
        }
        XCTAssertEqual(string, "ls: /bin/\(argument): No such file or directory\n")
    }
    
    func test___silence_listener() throws {
        let controller = try DefaultProcessController(
            subprocess: Subprocess(
                arguments: ["/bin/sleep", "10"],
                silenceBehavior: SilenceBehavior(
                    automaticAction: .noAutomaticAction,
                    allowedSilenceDuration: 0.01
                )
            )
        )
        
        let listenerCalled = expectation(description: "Silence listener has been invoked")
        
        controller.onSilence { sender, _ in
            sender.interruptAndForceKillIfNeeded()
            listenerCalled.fulfill()
        }
        controller.startAndListenUntilProcessDies()
        
        wait(for: [listenerCalled], timeout: 10)
    }
    
    func test___cancelling_stdout_listener___does_not_invoke_cancelled_listener_anymore() throws {
        let swiftTempFile = try TemporaryFile(suffix: ".swift")

        try prepareTestScriptToRun(
            swiftScriptPath: #file.deletingLastPathComponent.appending(pathComponent: "PrintSleepPrint.swift"),
            outputHandle: swiftTempFile.fileHandleForWriting
        )
        
        let controller = try DefaultProcessController(
            subprocess: Subprocess(
                arguments: ["/usr/bin/swift", swiftTempFile.absolutePath],
                environment: ["EMCEE_TEST_USE_STDERR": "false"]
            )
        )
        
        var collectedData = Data()
        
        controller.onStdout { _, data, unsubscriber in
            collectedData.append(contentsOf: data)
            unsubscriber()
        }
        controller.startAndListenUntilProcessDies()
        
        XCTAssertEqual(
            collectedData,
            "Print".data(using: .utf8)
        )
    }
    
    func test___cancelling_stderr_listener___does_not_invoke_cancelled_listener_anymore() throws {
        let swiftTempFile = try TemporaryFile(suffix: ".swift")

        try prepareTestScriptToRun(
            swiftScriptPath: #file.deletingLastPathComponent.appending(pathComponent: "PrintSleepPrint.swift"),
            outputHandle: swiftTempFile.fileHandleForWriting
        )
        
        let controller = try DefaultProcessController(
            subprocess: Subprocess(
                arguments: ["/usr/bin/swift", swiftTempFile.absolutePath],
                environment: ["EMCEE_TEST_USE_STDERR": "true"]
            )
        )
        
        var collectedData = Data()
        
        controller.onStderr { _, data, unsubscriber in
            collectedData.append(contentsOf: data)
            unsubscriber()
        }
        controller.startAndListenUntilProcessDies()
        
        XCTAssertEqual(
            collectedData,
            "Print".data(using: .utf8)
        )
    }

    
    func disabled_testWritingToStdin() throws {
        continueAfterFailure = true
        
        let stdoutFile = try TemporaryFile(deleteOnDealloc: false)
        let stderrFile = try TemporaryFile(deleteOnDealloc: false)
        let stdinFile = try TemporaryFile(deleteOnDealloc: false)
        let delegate = FakeDelegate(stream: true)

        let controller = try controllerForCommandLineTestExecutableTool(
            stdoutFile: stdoutFile.absolutePath,
            stderrFile: stderrFile.absolutePath,
            stdinFile: stdinFile.absolutePath,
            delegate: delegate
        )
        
        try controller.writeToStdIn(data: "hello, this is first stdin data!".data(using: .utf8)!)
        try controller.writeToStdIn(data: "hello, this is second stdin data!".data(using: .utf8)!)
        try controller.writeToStdIn(data: "bye".data(using: .utf8)!)
        controller.waitForProcessToDie()
        
        let stdoutString = try fileContents(path: stdoutFile.absolutePath)
        let stderrString = try fileContents(path: stderrFile.absolutePath)
        let stdinString = try fileContents(path: stdinFile.absolutePath)
        
        print("Stdout: \n" + stdoutString)
        print("Stderr: \n" + stderrString)
        print("Stdin: \n" + stdinString)
        
        XCTAssertEqual(
            stdinString,
            "hello, this is first stdin data!\n"
                + "hello, this is second stdin data!\n"
                + "bye\n")
        XCTAssertEqual(
            stdoutString,
            "stdin-to-stdout-streamer started!"
                + "hello, this is first stdin data!\n"
                + "hello, this is second stdin data!\n"
                + "bye\n")
    }
    
    func disabled_testWritingHugeData() throws {
        let stdoutFile = try TemporaryFile()
        let stderrFile = try TemporaryFile()
        let stdinFile = try TemporaryFile()
        let delegate = FakeDelegate(stream: false)
        
        let controller = try controllerForCommandLineTestExecutableTool(
            stdoutFile: stdoutFile.absolutePath,
            stderrFile: stderrFile.absolutePath,
            stdinFile: stdinFile.absolutePath,
            delegate: delegate
        )
        
        let inputString = Array(repeating: "qwertyuiop", count: 1000000).joined()
        
        try controller.writeToStdIn(data: inputString.data(using: .utf8)!)
        try controller.writeToStdIn(data: "bye".data(using: .utf8)!)
        controller.waitForProcessToDie()
        
        let stdoutString = try fileContents(path: stdoutFile.absolutePath)
        let stdinString = try fileContents(path: stdinFile.absolutePath)
        
        XCTAssertEqual(
            stdinString,
            inputString + "\n" + "bye\n")
        XCTAssertEqual(
            stdoutString,
            "stdin-to-stdout-streamer started!" + inputString + "\n" + "bye\n")
    }
    
    private func fileContents(path: AbsolutePath) throws -> String {
        let data = try Data(contentsOf: path.fileUrl)
        guard let contents = String(data: data, encoding: .utf8) else {
            fatalError("Unable to get contents of file: \(path)")
        }
        return contents
    }
    
    private func controllerForCommandLineTestExecutableTool(
        stdoutFile: AbsolutePath,
        stderrFile: AbsolutePath,
        stdinFile: AbsolutePath,
        delegate: ProcessControllerDelegate
    ) throws -> ProcessController {
        let streamingSwiftTempFile = try TemporaryFile(suffix: ".swift")
        try prepareTestScriptToRun(
            swiftScriptPath: #file.deletingLastPathComponent.appending(pathComponent: "StdInToStdOutStreamer.swift"),
            outputHandle: streamingSwiftTempFile.fileHandleForWriting
        )
        let compiledExecutable = try TemporaryFile()
        
        // precompile
        let compiler = try DefaultProcessController(
            subprocess: Subprocess(
                arguments: [
                    "/usr/bin/swiftc",
                    "-emit-executable",
                    streamingSwiftTempFile,
                    "-o", compiledExecutable]))
        compiler.startAndListenUntilProcessDies()
        
        // run the executable
        let controller = try DefaultProcessController(
            subprocess: Subprocess(
                arguments: [compiledExecutable],
                silenceBehavior: SilenceBehavior(
                    automaticAction: .noAutomaticAction,
                    allowedSilenceDuration: 0.0,
                    allowedTimeToConsumeStdin: 600
                ),
                standardStreamsCaptureConfig: StandardStreamsCaptureConfig(
                    stdoutContentsFile: stdoutFile,
                    stderrContentsFile: stderrFile,
                    stdinContentsFile: stdinFile
                )
            )
        )
        controller.delegate = delegate
        controller.start()
        return controller
    }
    
    private func prepareTestScriptToRun(swiftScriptPath: String, outputHandle: FileHandle) throws {
        var swiftTestCode = try String(contentsOfFile: swiftScriptPath)
        swiftTestCode = swiftTestCode.replacingOccurrences(of: "//uncomment_from_tests", with: "")
        outputHandle.write(swiftTestCode)
    }
}

extension TemporaryFile: SubprocessArgument {
    public func stringValue() throws -> String {
        return absolutePath.pathString
    }
}
