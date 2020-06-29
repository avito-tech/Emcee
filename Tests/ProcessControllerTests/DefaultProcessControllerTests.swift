import DateProvider
import Extensions
import FileSystem
import Foundation
import PathLib
import ProcessController
import TemporaryStuff
import TestHelpers
import XCTest

final class DefaultProcessControllerTests: XCTestCase {
    private let dateProvider = SystemDateProvider()
    private let fileSystem = LocalFileSystem()
    
    func testStartingSimpleSubprocess() throws {
        let controller = try DefaultProcessController(
            dateProvider: dateProvider,
            fileSystem: fileSystem,
            subprocess: Subprocess(
                arguments: ["/usr/bin/env"]
            )
        )
        controller.startAndListenUntilProcessDies()
        XCTAssertEqual(controller.processStatus(), .terminated(exitCode: 0))
    }
    
    func test___termination_status_is_running___when_process_is_running() throws {
        let controller = try DefaultProcessController(
            dateProvider: dateProvider,
            fileSystem: fileSystem,
            subprocess: Subprocess(
                arguments: ["/bin/sleep", "10"]
            )
        )
        controller.start()
        XCTAssertEqual(controller.processStatus(), .stillRunning)
    }
    
    func test___termination_status_is_not_started___when_process_has_not_yet_started() throws {
        let controller = try DefaultProcessController(
            dateProvider: dateProvider,
            fileSystem: fileSystem,
            subprocess: Subprocess(
                arguments: ["/usr/bin/env"]
            )
        )
        XCTAssertEqual(controller.processStatus(), .notStarted)
    }
    
    func test___process_cannot_be_started___when_file_does_not_exist() {
        assertThrows {
            try DefaultProcessController(
                dateProvider: dateProvider,
                fileSystem: fileSystem,
                subprocess: Subprocess(
                    arguments: ["/bin/non/existing/file/\(ProcessInfo.processInfo.globallyUniqueString)"]
                )
            )
        }
    }
    
    func test___process_cannot_be_started___when_file_is_not_executable() {
        let tempFile = assertDoesNotThrow { try TemporaryFile() }
        
        assertThrows {
            try DefaultProcessController(
                dateProvider: dateProvider,
                fileSystem: fileSystem,
                subprocess: Subprocess(
                    arguments: [tempFile]
                )
            )
        }
    }
    
    func test___successful_termination___does_not_throw() throws {
        let controller = assertDoesNotThrow {
            try DefaultProcessController(
                dateProvider: dateProvider,
                fileSystem: fileSystem,
                subprocess: Subprocess(
                    arguments: ["/usr/bin/env"]
                )
            )
        }
        assertDoesNotThrow {
            try controller.startAndWaitForSuccessfulTermination()
        }
    }
    
    func test___termination_with_non_zero_exit_code___throws() throws {
        let tempFile = assertDoesNotThrow { try TemporaryFile() }
        
        let argument = "/\(UUID().uuidString)"
        let controller = assertDoesNotThrow {
            try DefaultProcessController(
                dateProvider: dateProvider,
                fileSystem: fileSystem,
                subprocess: Subprocess(
                    arguments: ["/bin/ls", argument],
                    standardStreamsCaptureConfig: StandardStreamsCaptureConfig(
                        stderrPath: tempFile.absolutePath
                    )
                )
            )
        }
        controller.startAndListenUntilProcessDies()
        
        assertThrows {
            try controller.startAndWaitForSuccessfulTermination()
        }
    }
    
    func test___successful_execution() throws {
        let controller = try DefaultProcessController(
            dateProvider: dateProvider,
            fileSystem: fileSystem,
            subprocess: Subprocess(
                arguments: ["/bin/sleep", "0.01"]
            )
        )
        controller.startAndListenUntilProcessDies()
        XCTAssertEqual(controller.processStatus(), .terminated(exitCode: 0))
    }
        
    func test___automatic_interrupt_silence_handler() throws {
        let controller = try DefaultProcessController(
            dateProvider: dateProvider,
            fileSystem: fileSystem,
            subprocess: Subprocess(
                arguments: ["/bin/sleep", "999"],
                automaticManagement: .sigintThenKillIfSilent(interval: 0.00001)
            )
        )
        controller.startAndListenUntilProcessDies()
        XCTAssertEqual(controller.processStatus(), .terminated(exitCode: SIGINT))
    }
    
    func test___automatic_terminate_silence_handler() throws {
        let controller = try DefaultProcessController(
            dateProvider: dateProvider,
            fileSystem: fileSystem,
            subprocess: Subprocess(
                arguments: ["/bin/sleep", "999"],
                automaticManagement: .sigtermThenKillIfSilent(interval: 0.00001)
            )
        )
        controller.startAndListenUntilProcessDies()
        XCTAssertEqual(controller.processStatus(), .terminated(exitCode: SIGTERM))
    }
    
    func testWhenSubprocessFinishesSilenceIsNotReported() throws {
        let controller = try DefaultProcessController(
            dateProvider: dateProvider,
            fileSystem: fileSystem,
            subprocess: Subprocess(
                arguments: ["/bin/sleep"],
                automaticManagement: .sigtermThenKillIfSilent(interval: 10.0)
            )
        )
        var signalled = false
        controller.onSignal { _, _, _ in
            signalled = true
        }
        controller.startAndListenUntilProcessDies()

        XCTAssertFalse(signalled)
    }
    
    func test__executing_from_specific_working_directory() throws {
        let temporaryFolder = try TemporaryFolder()
        
        let controller = try DefaultProcessController(
            dateProvider: dateProvider,
            fileSystem: fileSystem,
            subprocess: Subprocess(
                arguments: ["/bin/pwd"],
                workingDirectory: temporaryFolder.absolutePath
            )
        )
        controller.startAndListenUntilProcessDies()
        
        XCTAssertEqual(
            try String(contentsOfFile: controller.subprocess.standardStreamsCaptureConfig.stdoutOutputPath().pathString),
            temporaryFolder.absolutePath.pathString + "\n"
        )
    }
    
    func testGettingStdout() throws {
        let tempFile = try TemporaryFile()
        
        let controller = try DefaultProcessController(
            dateProvider: dateProvider,
            fileSystem: fileSystem,
            subprocess: Subprocess(
                arguments: ["/bin/ls", "/"],
                standardStreamsCaptureConfig: StandardStreamsCaptureConfig(
                    stdoutPath: tempFile.absolutePath
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
            dateProvider: dateProvider,
            fileSystem: fileSystem,
            subprocess: Subprocess(
                arguments: ["/bin/ls", argument],
                standardStreamsCaptureConfig: StandardStreamsCaptureConfig(
                    stderrPath: tempFile.absolutePath
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
            dateProvider: dateProvider,
            fileSystem: fileSystem,
            subprocess: Subprocess(
                arguments: ["/bin/ls", "/", argument],
                standardStreamsCaptureConfig: StandardStreamsCaptureConfig(
                    stdoutPath: stdoutFile.absolutePath,
                    stderrPath: stderrFile.absolutePath
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
            dateProvider: dateProvider,
            fileSystem: fileSystem,
            subprocess: Subprocess(
                arguments: ["/bin/ls", "/bin/ls"],
                environment: ["NSUnbufferedIO": "YES"]
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
            dateProvider: dateProvider,
            fileSystem: fileSystem,
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
    
    func test___start_listener() throws {
        let argument = UUID().uuidString + UUID().uuidString
        
        let controller = try DefaultProcessController(
            dateProvider: dateProvider,
            fileSystem: fileSystem,
            subprocess: Subprocess(
                arguments: ["/bin/ls", "/bin/" + argument]
            )
        )
        
        let handlerInvoked = XCTestExpectation(description: "Start handler has been invoked")
        controller.onStart { _, _ in
            handlerInvoked.fulfill()
        }
        controller.startAndListenUntilProcessDies()
        
        wait(for: [handlerInvoked], timeout: 10)
    }
    
    func test___termination_listener() throws {
        let argument = UUID().uuidString + UUID().uuidString
        
        let controller = try DefaultProcessController(
            dateProvider: dateProvider,
            fileSystem: fileSystem,
            subprocess: Subprocess(
                arguments: ["/bin/ls", "/bin/" + argument]
            )
        )
        
        let handlerInvoked = XCTestExpectation(description: "Termination handler has been invoked")
        controller.onTermination { _, _ in
            handlerInvoked.fulfill()
        }
        controller.startAndListenUntilProcessDies()
        
        wait(for: [handlerInvoked], timeout: 10)
    }
    
    func test___sigterm_is_sent___when_silent() throws {
        let controller = try DefaultProcessController(
            dateProvider: dateProvider,
            fileSystem: fileSystem,
            subprocess: Subprocess(
                arguments: ["/bin/sleep", "10"],
                automaticManagement: .sigtermThenKillIfSilent(interval: 0.01)
            )
        )
        
        let listenerCalled = expectation(description: "Silence listener has been invoked")
        
        controller.onSignal { sender, signal, unsubscriber in
            XCTAssertEqual(signal, SIGTERM)
            unsubscriber()
            listenerCalled.fulfill()
        }
        controller.start()
        defer { controller.forceKillProcess() }
        
        wait(for: [listenerCalled], timeout: 10)
    }
    
    func test___sigint_is_sent___when_silent() throws {
        let controller = try DefaultProcessController(
            dateProvider: dateProvider,
            fileSystem: fileSystem,
            subprocess: Subprocess(
                arguments: ["/bin/sleep", "10"],
                automaticManagement: .sigintThenKillIfSilent(interval: 0.01)
            )
        )
        
        let listenerCalled = expectation(description: "Silence listener has been invoked")
        
        controller.onSignal { sender, signal, unsubscriber in
            XCTAssertEqual(signal, SIGINT)
            unsubscriber()
            listenerCalled.fulfill()
        }
        controller.start()
        defer { controller.forceKillProcess() }
        
        wait(for: [listenerCalled], timeout: 10)
    }
    
    func test___sigint_is_sent___when_running_for_too_long() throws {
        let controller = try DefaultProcessController(
            dateProvider: dateProvider,
            fileSystem: fileSystem,
            subprocess: Subprocess(
                arguments: ["/usr/bin/yes"],
                automaticManagement: .sigintThenKillAfterRunningFor(interval: 1)
            )
        )
        
        let listenerCalled = expectation(description: "Signal listener has been invoked")
        
        controller.onSignal { sender, signal, unsubscriber in
            XCTAssertEqual(signal, SIGINT)
            unsubscriber()
            listenerCalled.fulfill()
        }
        controller.start()
        defer { controller.forceKillProcess() }
        wait(for: [listenerCalled], timeout: 10)
    }
    
    func test___sigterm_is_sent___when_running_for_too_long() throws {
        let controller = try DefaultProcessController(
            dateProvider: dateProvider,
            fileSystem: fileSystem,
            subprocess: Subprocess(
                arguments: ["/usr/bin/yes"],
                automaticManagement: .sigtermThenKillAfterRunningFor(interval: 1)
            )
        )
        
        let listenerCalled = expectation(description: "Signal listener has been invoked")
        
        controller.onSignal { sender, signal, unsubscriber in
            XCTAssertEqual(signal, SIGTERM)
            unsubscriber()
            listenerCalled.fulfill()
        }
        controller.start()
        defer { controller.forceKillProcess() }
        wait(for: [listenerCalled], timeout: 10)
    }
    
    func test___cancelling_stdout_listener___does_not_invoke_cancelled_listener_anymore() throws {
        let controller = try DefaultProcessController(
            dateProvider: dateProvider,
            fileSystem: fileSystem,
            subprocess: Subprocess(
                arguments: ["/bin/sh", "-c", "echo aa; sleep 3; echo aa"]
            )
        )
        
        var collectedData = Data()
        
        controller.onStdout { sender, data, unsubscriber in
            collectedData.append(contentsOf: data)
            unsubscriber()
        }
        controller.startAndListenUntilProcessDies()
        
        XCTAssertEqual(
            collectedData,
            "aa\n".data(using: .utf8)
        )
    }
    
    func test___cancelling_stderr_listener___does_not_invoke_cancelled_listener_anymore() throws {
        let controller = try DefaultProcessController(
            dateProvider: dateProvider,
            fileSystem: fileSystem,
            subprocess: Subprocess(
                arguments: ["/bin/sh", "-c", ">&2 echo aa; sleep 3; echo aa"]
            )
        )
        
        var collectedData = Data()
        
        controller.onStderr { sender, data, unsubscriber in
            collectedData.append(contentsOf: data)
            unsubscriber()
        }
        controller.startAndListenUntilProcessDies()
        
        XCTAssertEqual(
            collectedData,
            "aa\n".data(using: .utf8)
        )
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
        stdinFile: AbsolutePath
    ) throws -> ProcessController {
        let streamingSwiftTempFile = try TemporaryFile(suffix: ".swift")
        try prepareTestScriptToRun(
            swiftScriptPath: #file.deletingLastPathComponent.appending(pathComponent: "StdInToStdOutStreamer.swift"),
            outputHandle: streamingSwiftTempFile.fileHandleForWriting
        )
        let compiledExecutable = try TemporaryFile()
        
        // precompile
        let compiler = try DefaultProcessController(
            dateProvider: dateProvider,
            fileSystem: fileSystem,
            subprocess: Subprocess(
                arguments: [
                    "/usr/bin/swiftc",
                    "-emit-executable",
                    streamingSwiftTempFile,
                    "-o", compiledExecutable]))
        compiler.startAndListenUntilProcessDies()
        
        // run the executable
        let controller = try DefaultProcessController(
            dateProvider: dateProvider,
            fileSystem: fileSystem,
            subprocess: Subprocess(
                arguments: [compiledExecutable],
                standardStreamsCaptureConfig: StandardStreamsCaptureConfig(
                    stdoutPath: stdoutFile,
                    stderrPath: stderrFile
                )
            )
        )
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
