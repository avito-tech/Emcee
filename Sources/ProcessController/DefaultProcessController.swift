import Dispatch
import Extensions
import Foundation
import Logging
import PathLib
import Timer

public final class DefaultProcessController: ProcessController, CustomStringConvertible {
    public let subprocess: Subprocess
    private let process: Process
    public let processName: String
    private var didInitiateKillOfProcess = false
    private var lastDataTimestamp: TimeInterval = Date().timeIntervalSince1970
    private let processTerminationQueue = DispatchQueue(label: "DefaultProcessController.processTerminationQueue")
    private let stdinWriteQueue = DispatchQueue(label: "DefaultProcessController.stdinWriteQueue")
    private var silenceTrackingTimer: DispatchBasedTimer?
    private var stdinHandle: FileHandle?
    private let processStdinPipe = Pipe()
    private let openPipeFileHandleGroup = DispatchGroup()
    private static let newLineCharacterData = Data([UInt8(10)])
    private var stdoutListeners = [ListenerWrapper<StdoutListener>]()
    private var stderrListeners = [ListenerWrapper<StderrListener>]()
    private var silenceListeners = [ListenerWrapper<SilenceListener>]()
    private let listenerQueue = DispatchQueue(label: "DefaultProcessController.listenerQueue")
    private var didStartProcess = false
    public private(set) var processId: Int32 = 0
    public weak var delegate: ProcessControllerDelegate?
    
    private final class ListenerWrapper<T> {
        let uuid: UUID
        let listener: T

        init(uuid: UUID, listener: T) {
            self.uuid = uuid
            self.listener = listener
        }
    }
    
    public init(subprocess: Subprocess) throws {
        self.subprocess = subprocess
        let arguments = try subprocess.arguments.map { try $0.stringValue() }
        processName = arguments.elementAtIndex(0, "First element is path to executable").lastPathComponent
        process = try DefaultProcessController.createProcess(
            arguments: arguments,
            environment: subprocess.environment,
            processStdinPipe: processStdinPipe,
            workingDirectory: subprocess.workingDirectory
        )
        setUpProcessListening()
    }
    
    private static func createProcess(
        arguments: [String],
        environment: [String: String],
        processStdinPipe: Pipe,
        workingDirectory: AbsolutePath
    ) throws -> Process {
        let process = Process()
        process.launchPath = arguments.elementAtIndex(0, "Path to executable")
        process.arguments = Array(arguments.dropFirst())
        process.environment = environment
        process.standardInput = processStdinPipe
        process.currentDirectoryPath = workingDirectory.pathString
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
        Logger.debug("Starting subprocess: \(subprocess)", subprocessInfo)
        process.launch()
        process.terminationHandler = { _ in
            OrphanProcessTracker().removeProcessFromCleanup(pid: self.processId, name: self.processName)
            self.closeFileHandles()
        }
        processId = process.processIdentifier
        OrphanProcessTracker().storeProcessForCleanup(pid: processId, name: processName)
        Logger.debug("Started process \(processId)", subprocessInfo)
        startMonitoringForHangs()
        
        onStdout { processController, data, _ in processController.delegate?.processController(processController, newStdoutData: data) }
        onStderr { processController, data, _ in processController.delegate?.processController(processController, newStderrData: data) }
        onSilence { processController, _ in processController.delegate?.processControllerDidNotReceiveAnyOutputWithinAllowedSilenceDuration(processController) }
    }
    
    public func waitForProcessToDie() {
        process.waitUntilExit()
        openPipeFileHandleGroup.wait()
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
        let consumeWaiter = DispatchGroup()
        consumeWaiter.enter()
        
        stdinWriteQueue.async {
            self.processStdinPipe.fileHandleForWriting.write(data)
            self.stdinHandle?.write(data)
            if self.subprocess.silenceBehavior.allowedTimeToConsumeStdin > 0 {
                consumeWaiter.leave()
            }
        }
        
        if consumeWaiter.wait(timeout: .now() + subprocess.silenceBehavior.allowedTimeToConsumeStdin) == .timedOut {
            throw StdinError.didNotConsumeStdinInTime(self)
        }
    }
    
    public func terminateAndForceKillIfNeeded() {
        attemptToKillProcess { process in
            Logger.debug("Terminating the process", subprocessInfo)
            process.terminate()
        }
    }
    
    public func interruptAndForceKillIfNeeded() {
        attemptToKillProcess { process in
            Logger.debug("Interrupting the process", subprocessInfo)
            process.interrupt()
        }
    }
    
    public func onStdout(listener: @escaping StdoutListener) {
        stdoutListeners.append(ListenerWrapper(uuid: UUID(), listener: listener))
    }
    
    public func onStderr(listener: @escaping StderrListener) {
        stderrListeners.append(ListenerWrapper(uuid: UUID(), listener: listener))
    }
    
    public func onSilence(listener: @escaping SilenceListener) {
        silenceListeners.append(ListenerWrapper(uuid: UUID(), listener: listener))
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
            Logger.warning("Failed to interrupt the process in time, terminating", subprocessInfo)
            kill(-processId, SIGKILL)
            
            stdoutListeners.removeAll()
            stderrListeners.removeAll()
            silenceListeners.removeAll()
        }
    }
    
    // MARK: - Hang Monitoring
    
    private func startMonitoringForHangs() {
        guard subprocess.silenceBehavior.allowedSilenceDuration > 0 else {
            Logger.debug("Will not track hangs as allowedSilenceDuration must be positive", subprocessInfo)
            return
        }
        
        Logger.debug("Will track silences with timeout \(subprocess.silenceBehavior.allowedSilenceDuration)", subprocessInfo)
        
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
        Logger.error("Detected a long period of silence of \(processName)", subprocessInfo)
        
        listenerQueue.async {
            for listenerWrapper in self.silenceListeners {
                let unsubscriber: Unsubscribe = {
                    self.listenerQueue.async {
                        self.silenceListeners.removeAll { $0.uuid == listenerWrapper.uuid }
                    }
                }
                listenerWrapper.listener(self, unsubscriber)
            }
        }
        
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
    
    private func streamFromPipeIntoHandle(
        pipe: Pipe,
        storageHandle: FileHandle,
        onNewData: @escaping (Data) -> (),
        onEndOfData: @escaping () -> Void
    ) {
        pipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            if data.isEmpty {
                storageHandle.closeFile()
                handle.readabilityHandler = nil
                onEndOfData()
            } else {
                storageHandle.write(data)
                onNewData(data)
            }
        }
    }
    
    private func setUpProcessListening() {
        storeStdForProcess(
            path: subprocess.standardStreamsCaptureConfig.stdoutContentsFile,
            onError: { message in
                Logger.warning("Will not store stdout output: \(message)", subprocessInfo)
            },
            pipeAssigningClosure: { pipe in
                self.process.standardOutput = pipe
                self.openPipeFileHandleGroup.enter()
            },
            onNewData: didReceiveStdout,
            onEndOfData: {
                self.openPipeFileHandleGroup.leave()
            }
        )
        
        storeStdForProcess(
            path: subprocess.standardStreamsCaptureConfig.stderrContentsFile,
            onError: { message in
                Logger.warning("Will not store stderr output: \(message)", subprocessInfo)
            },
            pipeAssigningClosure: { pipe in
                self.process.standardError = pipe
                self.openPipeFileHandleGroup.enter()
            },
            onNewData: didReceiveStderr,
            onEndOfData: {
                self.openPipeFileHandleGroup.leave()
            }
        )
        
        if FileManager.default.createFile(atPath: subprocess.standardStreamsCaptureConfig.stdinContentsFile.pathString, contents: nil),
            let stdinHandle = FileHandle(forWritingAtPath: subprocess.standardStreamsCaptureConfig.stdinContentsFile.pathString)
        {
            self.stdinHandle = stdinHandle
        } else {
            Logger.warning("Will not store stdin input at file, failed to open a file handle", subprocessInfo)
        }
    }
    
    private func storeStdForProcess(
        path: AbsolutePath,
        onError: (String) -> (),
        pipeAssigningClosure: (Pipe) -> (),
        onNewData: @escaping (Data) -> (),
        onEndOfData: @escaping () -> ()
    ) {
        guard FileManager.default.createFile(atPath: path.pathString, contents: nil) else {
            onError("Failed to create a file at path: '\(path)'")
            return
        }
        guard let storageHandle = FileHandle(forWritingAtPath: path.pathString) else {
            onError("Failed to open file handle")
            return
        }
        let pipe = Pipe()
        pipeAssigningClosure(pipe)
        streamFromPipeIntoHandle(
            pipe: pipe,
            storageHandle: storageHandle,
            onNewData: { data in
                self.didProcessDataFromProcess()
                onNewData(data)
            },
            onEndOfData: {
                onEndOfData()
            }
        )
    }
    
    private func didReceiveStdout(data: Data) {
        listenerQueue.async {
            for listenerWrapper in self.stdoutListeners {
                let unsubscriber: Unsubscribe = {
                    self.listenerQueue.async {
                        self.stdoutListeners.removeAll { $0.uuid == listenerWrapper.uuid }
                    }
                }
                listenerWrapper.listener(self, data, unsubscriber)
            }
        }
    }
    
    private func didReceiveStderr(data: Data) {
        listenerQueue.async {
            for listenerWrapper in self.stderrListeners {
                let unsubscriber: Unsubscribe = {
                    self.listenerQueue.async {
                        self.stderrListeners.removeAll { $0.uuid == listenerWrapper.uuid }
                    }
                }
                listenerWrapper.listener(self, data, unsubscriber)
            }
        }
    }
    
    private func didProcessDataFromProcess() {
        lastDataTimestamp = Date().timeIntervalSince1970
    }
}

