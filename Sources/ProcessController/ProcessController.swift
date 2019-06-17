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
    private static let newLineCharacterData = Data([UInt8(10)])
    
    private var didStartProcess = false
    public var processId: Int32 = 0
    public weak var delegate: ProcessControllerDelegate?
    
    public init(subprocess: Subprocess) throws {
        self.subprocess = subprocess
        let arguments = try subprocess.arguments.map { try $0.stringValue() }
        processName = arguments.elementAtIndex(0, "First element is path to executable").lastPathComponent
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
        return "<\(type(of: self)): \(executable) \(args) \(processStatus())>"
    }
    
    // MARK: - Launch and Kill
    
    public func start() {
        if didStartProcess {
            return
        }
        
        didStartProcess = true
        Logger.debug("Starting subprocess: \(subprocess)", subprocessInfo: SubprocessInfo(subprocessId: 0, subprocessName: processName))
        process.launch()
        process.terminationHandler = { _ in
            OrphanProcessTracker().removeProcessFromCleanup(pid: self.processId, name: self.processName)
            self.closeFileHandles()
        }
        processId = process.processIdentifier
        OrphanProcessTracker().storeProcessForCleanup(pid: processId, name: processName)
        Logger.debug("Started process \(processId)", subprocessInfo: SubprocessInfo(subprocessId: processId, subprocessName: processName))
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
    
    public func processStatus() -> ProcessStatus {
        if !didStartProcess {
            return .notStarted
        }
        if process.isRunning {
            return .stillRunning
        }
        return .terminated(exitCode: process.terminationStatus)
    }
    
    public func writeToStdIn(data: Data) throws {
        guard isProcessRunning else { throw StdinError.processIsNotRunning(self) }
        let condition = NSCondition()
        
        stdinWriteQueue.async {
            self.processStdinPipe.fileHandleForWriting.write(data)
            self.processStdinPipe.fileHandleForWriting.write("\n")
            
            self.stdinHandle?.write(data)
            self.stdinHandle?.write("\n")
            if self.subprocess.silenceBehavior.allowedTimeToConsumeStdin > 0 {
                condition.signal()
            }
        }
        
        if !condition.wait(until: Date().addingTimeInterval(subprocess.silenceBehavior.allowedTimeToConsumeStdin)) {
            throw StdinError.didNotConsumeStdinInTime(self)
        }
    }
    
    public func terminateAndForceKillIfNeeded() {
        attemptToKillProcess { process in
            Logger.debug("Terminating the process", subprocessInfo: SubprocessInfo(subprocessId: processId, subprocessName: processName))
            process.terminate()
        }
    }
    
    public func interruptAndForceKillIfNeeded() {
        attemptToKillProcess { process in
            Logger.debug("Interrupting the process", subprocessInfo: SubprocessInfo(subprocessId: processId, subprocessName: processName))
            process.interrupt()
        }
    }
    
    private func attemptToKillProcess(killer: (Process) -> ()) {
        processTerminationQueue.sync {
            guard self.didInitiateKillOfProcess == false else { return }
            self.didInitiateKillOfProcess = true
            killer(process)
            processTerminationQueue.asyncAfter(deadline: .now() + 15.0) {
                self.forceKillProcess()
            }
        }
    }
    
    private func forceKillProcess() {
        if isProcessRunning {
            Logger.warning("Failed to interrupt the process in time, terminating", subprocessInfo: SubprocessInfo(subprocessId: processId, subprocessName: processName))
            kill(-processId, SIGKILL)
        }
    }
    
    // MARK: - Hang Monitoring
    
    private func startMonitoringForHangs() {
        guard subprocess.silenceBehavior.allowedSilenceDuration > 0 else {
            Logger.debug("Will not track hangs as allowedSilenceDuration must be positive", subprocessInfo: SubprocessInfo(subprocessId: processId, subprocessName: processName))
            return
        }
        
        Logger.debug("Will track silences with timeout \(subprocess.silenceBehavior.allowedSilenceDuration)", subprocessInfo: SubprocessInfo(subprocessId: processId, subprocessName: processName))
        
        silenceTrackingTimer = DispatchBasedTimer.startedTimer(repeating: .seconds(1), leeway: .seconds(1)) { [weak self] timer in
            guard let strongSelf = self else {
                timer.stop()
                return
            }
            if Date().timeIntervalSince1970 - strongSelf.lastDataTimestamp > strongSelf.subprocess.silenceBehavior.allowedSilenceDuration {
                strongSelf.didDetectLongPeriodOfSilence()
                timer.stop()
            }
        }
    }
    
    private func didDetectLongPeriodOfSilence() {
        silenceTrackingTimer?.stop()
        silenceTrackingTimer = nil
        Logger.error("Detected a long period of silence of \(processName)", subprocessInfo: SubprocessInfo(subprocessId: processId, subprocessName: processName))
        delegate?.processControllerDidNotReceiveAnyOutputWithinAllowedSilenceDuration(self)
        
        switch subprocess.silenceBehavior.automaticAction {
        case .noAutomaticAction:
            break
        case .terminateAndForceKill:
            terminateAndForceKillIfNeeded()
        case .interruptAndForceKill:
            interruptAndForceKillIfNeeded()
        case .handler(let handler):
            handler(self)
        }
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
                Logger.warning("Will not store stdout output: \(message)", subprocessInfo: SubprocessInfo(subprocessId: processId, subprocessName: processName))
            },
            pipeAssigningClosure: { pipe in
                Logger.debug("Will store stdout output at: \(stdoutContentsFile)", subprocessInfo: SubprocessInfo(subprocessId: processId, subprocessName: processName))
                self.process.standardOutput = pipe
            },
            onNewData: { data in
                self.delegate?.processController(self, newStdoutData: data)
            }
        )
        
        storeStdForProcess(
            path: stderrContentsFile,
            onError: { message in
                Logger.warning("Will not store stderr output: \(message)", subprocessInfo: SubprocessInfo(subprocessId: processId, subprocessName: processName))
            },
            pipeAssigningClosure: { pipe in
                Logger.debug("Will store stderr output at: \(stderrContentsFile)", subprocessInfo: SubprocessInfo(subprocessId: processId, subprocessName: processName))
                self.process.standardError = pipe
            },
            onNewData: { data in
                self.delegate?.processController(self, newStderrData: data)
            }
        )
        
        if FileManager.default.createFile(atPath: stdinContentsFile, contents: nil),
            let stdinHandle = FileHandle(forWritingAtPath: stdinContentsFile)
        {
            Logger.debug("Will store stdin input at: \(stdinContentsFile)", subprocessInfo: SubprocessInfo(subprocessId: processId, subprocessName: processName))
            self.stdinHandle = stdinHandle
        } else {
            Logger.warning("Will not store stdin input at file, failed to open a file handle", subprocessInfo: SubprocessInfo(subprocessId: processId, subprocessName: processName))
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
