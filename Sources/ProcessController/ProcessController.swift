import Extensions
import Foundation
import Dispatch
import Logging
import Timer

public final class ProcessController: CustomStringConvertible {
    private let subprocess: Subprocess
    private let process: Process
    public let processName: String
    private var didInitiateKillOfProcess = false
    private var lastDataTimestamp: TimeInterval = Date().timeIntervalSince1970
    private let processTerminationQueue = DispatchQueue(label: "ru.avito.runner.ProcessListener.processTerminationQueue")
    private let stdReadQueue = DispatchQueue(label: "ru.avito.runner.ProcessListener.stdReadQueue", attributes: .concurrent)
    private let stdinWriteQueue = DispatchQueue(label: "ru.avito.runner.ProcessListener.stdinWriteQueue")
    private var silenceTrackingTimer: DispatchBasedTimer?
    private var stdinHandle: FileHandle?
    private let processStdinPipe = Pipe()
    private static let newLineCharacterData = Data(bytes: [UInt8(10)])
    
    private var didStartProcess = false
    public var processId: Int32 = 0
    public weak var delegate: ProcessControllerDelegate?
    
    public init(subprocess: Subprocess) throws {
        self.subprocess = subprocess
        let arguments = try subprocess.arguments.map { try $0.stringValue() }
        self.processName = arguments.elementAtIndex(0, "First element is path to executable").lastPathComponent
        self.process = try ProcessController.createProcess(
            arguments: arguments,
            environment: subprocess.environment,
            processStdinPipe: processStdinPipe)
        setUpProcessListening()
    }
    
    private static func createProcess(arguments: [String], environment: [String: String], processStdinPipe: Pipe) throws -> Process {
        let process = Process()
        process.launchPath = arguments.elementAtIndex(0, "Path to executable")
        process.arguments = Array(arguments.dropFirst())
        process.environment = environment
        process.standardInput = processStdinPipe
        try process.setStartsNewProcessGroup(false)
        return process
    }
    
    public var description: String {
        let executable = process.launchPath ?? "unknown executable"
        let args = process.arguments?.joined(separator: " ") ?? ""
        let status = isProcessRunning ? "running" : (didStartProcess ? "finished with code \(terminationStatus() ?? -5)" : "not started")
        return "<\(type(of: self)): \(executable) \(args) \(status)>"
    }
    
    // MARK: - Launch and Kill
    
    public func start() {
        if didStartProcess {
            return
        }
        
        didStartProcess = true
        log("Starting subprocess: \(subprocess)", subprocessName: self.processName)
        process.launch()
        process.terminationHandler = { _ in
            OrphanProcessTracker().removeProcessFromCleanup(pid: self.processId, name: self.processName)
            self.closeFileHandles()
        }
        processId = process.processIdentifier
        OrphanProcessTracker().storeProcessForCleanup(pid: processId, name: processName)
        log("Started process \(processId)", subprocessName: self.processName, subprocessId: processId, color: .boldBlue)
        startMonitoringForHangs()
    }
    
    public func startAndListenUntilProcessDies() {
        start()
        waitForProcessToDie()
    }
    
    public func waitForProcessToDie() {
        process.waitUntilExit()
    }
    
    public var isProcessRunning: Bool {
        if !didStartProcess {
            return false
        }
        return process.isRunning
    }
    
    public func terminationStatus() -> Int32? {
        if !didStartProcess || process.isRunning {
            return nil
        }
        return process.terminationStatus
    }
    
    public func writeToStdIn(data: Data) throws {
        guard isProcessRunning else { throw StdinError.processIsNotRunning(self) }
        let condition = NSCondition()
        
        stdinWriteQueue.async {
            self.processStdinPipe.fileHandleForWriting.write(data)
            self.processStdinPipe.fileHandleForWriting.write("\n")
            
            self.stdinHandle?.write(data)
            self.stdinHandle?.write("\n")
            if self.subprocess.allowedTimeToConsumeStdin > 0 {
                condition.signal()
            }
        }
        
        if !condition.wait(until: Date().addingTimeInterval(subprocess.allowedTimeToConsumeStdin)) {
            throw StdinError.didNotConsumeStdinInTime(self)
        }
    }
    
    public func interruptAndForceKillIfNeeded() {
        processTerminationQueue.sync {
            guard self.didInitiateKillOfProcess == false else { return }
            self.didInitiateKillOfProcess = true
            log("Interrupting the process", subprocessName: self.processName, subprocessId: processId, color: .red)
            process.interrupt()
            processTerminationQueue.asyncAfter(deadline: .now() + 15.0) {
                self.forceKillProcess()
            }
        }
    }
    
    private func forceKillProcess() {
        if isProcessRunning {
            log("Failed to interrupt the process in time, terminating", subprocessName: self.processName, subprocessId: processId, color: .boldRed)
            process.terminate()
        }
    }
    
    // MARK: - Hang Monitoring
    
    private func startMonitoringForHangs() {
        guard subprocess.maximumAllowedSilenceDuration > 0 else {
            log("Will not track hangs as maximumAllowedSilenceDuration must be positive, but it is \(subprocess.maximumAllowedSilenceDuration)", subprocessName: self.processName, subprocessId: processId, color: .yellow)
            return
        }
        
        log("Will track silences with timeout \(subprocess.maximumAllowedSilenceDuration)", subprocessName: self.processName, subprocessId: processId, color: .boldBlue)
        
        silenceTrackingTimer = DispatchBasedTimer.startedTimer(repeating: .seconds(1), leeway: .seconds(1)) { [weak self] in
            guard let strongSelf = self else { return }
            if Date().timeIntervalSince1970 - strongSelf.lastDataTimestamp > strongSelf.subprocess.maximumAllowedSilenceDuration {
                strongSelf.didDetectLongPeriodOfSilence()
            }
        }
    }
    
    private func didDetectLongPeriodOfSilence() {
        silenceTrackingTimer?.stop()
        silenceTrackingTimer = nil
        log("Detected a long period of silence", subprocessName: self.processName, subprocessId: processId, color: .red)
        delegate?.processControllerDidNotReceiveAnyOutputWithinAllowedSilenceDuration(self)
    }
    
    private func closeFileHandles() {
        stdinHandle?.closeFile()
        stdinHandle = nil
    }
    
    // MARK: - Processing Output
    
    private func streamFromPipeIntoHandle(_ pipe: Pipe, _ storageHandle: FileHandle, onNewData: @escaping (Data) -> ()) {
        pipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            if data.isEmpty {
                storageHandle.closeFile()
                pipe.fileHandleForReading.readabilityHandler = nil
            } else {
                storageHandle.write(data)
                onNewData(data)
            }
        }
    }
    
    private func setUpProcessListening() {
        let uuid = UUID().uuidString
        let stdoutContentsFile = subprocess.stdoutContentsFile ?? NSTemporaryDirectory().appending("\(uuid)_\(processName)_stdout.txt")
        let stderrContentsFile = subprocess.stderrContentsFile ?? NSTemporaryDirectory().appending("\(uuid)_\(processName)_stderr.txt")
        let stdinContentsFile = subprocess.stdinContentsFile ?? NSTemporaryDirectory().appending("\(uuid)_\(processName)_stdin.txt")
        
        storeStdForProcess(
            path: stdoutContentsFile,
            onError: { message in
                log("WARNING: Will not store stdout output: \(message)", subprocessName: self.processName, subprocessId: self.processId, color: .yellow)
            },
            pipeAssigningClosure: { pipe in
                log("Will store stdout output at: \(stdoutContentsFile)", subprocessName: self.processName, subprocessId: self.processId, color: .blue)
                self.process.standardOutput = pipe
            },
            onNewData: { data in
                self.delegate?.processController(self, newStdoutData: data)
            }
        )
        
        storeStdForProcess(
            path: stderrContentsFile,
            onError: { message in
                log("WARNING: Will not store stderr output: \(message)", subprocessName: self.processName, subprocessId: self.processId, color: .yellow)
            },
            pipeAssigningClosure: { pipe in
                log("Will store stderr output at: \(stderrContentsFile)", subprocessName: self.processName, subprocessId: self.processId, color: .blue)
                self.process.standardError = pipe
            },
            onNewData: { data in
                self.delegate?.processController(self, newStderrData: data)
            }
        )
        
        if FileManager.default.createFile(atPath: stdinContentsFile, contents: nil),
            let stdinHandle = FileHandle(forWritingAtPath: stdinContentsFile)
        {
            log("Will store stdin input at: \(stdinContentsFile)", subprocessName: self.processName, subprocessId: processId, color: .blue)
            self.stdinHandle = stdinHandle
        } else {
            log("WARNING: Will not store stdin input at file, failed to open a file handle", color: .yellow)
        }
    }
    
    private func storeStdForProcess(
        path: String,
        onError: (String) -> (),
        pipeAssigningClosure: (Pipe) -> (),
        onNewData: @escaping (Data) -> ())
    {
        guard FileManager.default.createFile(atPath: path, contents: nil) else {
            onError("Failed to create a file at path: '\(path)'")
            return
        }
        guard let storageHandle = FileHandle(forWritingAtPath: path) else {
            onError("Failed to open file handle")
            return
        }
        let pipe = Pipe()
        pipeAssigningClosure(pipe)
        streamFromPipeIntoHandle(pipe, storageHandle) { data in
            self.didProcessDataFromProcess()
            onNewData(data)
        }
    }
    
    private func didProcessDataFromProcess() {
        lastDataTimestamp = Date().timeIntervalSince1970
    }
}
