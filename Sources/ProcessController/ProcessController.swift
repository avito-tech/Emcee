import Extensions
import Foundation
import Dispatch
import Logging

public final class ProcessController {
    private let process: Process
    public let processName: String
    private var didInitiateKillOfProcess = false
    private let maximumAllowedSilenceDuration: TimeInterval
    private var lastDataTimestamp: TimeInterval = Date().timeIntervalSince1970
    private let processTerminationQueue = DispatchQueue(label: "ru.avito.runner.ProcessListener.processTerminationQueue")
    private let silenceTrackingTimerQueue = DispatchQueue(label: "ru.avito.runner.ProcessListener.silenceTrackingTimerQueue")
    private var silenceTrackingTimer: DispatchSourceTimer?
    
    private let uuid = UUID().uuidString
    private lazy var stdoutContentsFile = NSTemporaryDirectory().appending("\(uuid)_stdout.txt")
    private lazy var stderrContentsFile = NSTemporaryDirectory().appending("\(uuid)_stderr.txt")
    private var stdoutHandle: FileHandle?
    private var stderrHandle: FileHandle?
    
    private var didStartProcess = false
    public var processId: Int32 = 0
    public weak var delegate: ProcessControllerDelegate?
    
    public init(subprocess: Subprocess, maximumAllowedSilenceDuration: TimeInterval?) {
        self.process = ProcessController.createProcess(subprocess)
        self.processName = subprocess.arguments[0].lastPathComponent
        self.maximumAllowedSilenceDuration = maximumAllowedSilenceDuration ?? 0
        setUpProcessListening()
    }
    
    private static func createProcess(_ subprocess: Subprocess) -> Process {
        let executable = subprocess.arguments[0]
        let process = Process()
        process.launchPath = executable
        process.arguments = Array(subprocess.arguments.dropFirst())
        process.environment = subprocess.environment
        do {
            try process.setStartsNewProcessGroup(false)
        } catch {
            log("WARNING: \(error)", color: .yellow)
        }
        return process
    }
    
    deinit {
        silenceTrackingTimer?.cancel()
    }
    
    // MARK: - Launch and Kill
    
    public func start() {
        if didStartProcess {
            return
        }
        
        didStartProcess = true
        log("Starting process", subprocessName: self.processName)
        openFileHandles()
        process.launch()
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
        OrphanProcessTracker().removeProcessFromCleanup(pid: processId, name: processName)
        closeFileHandles()
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
        closeFileHandles()
    }
    
    // MARK: - Hang Monitoring
    
    private func startMonitoringForHangs() {
        guard maximumAllowedSilenceDuration > 0 else {
            log("Can't track hangs as maximumAllowedSilenceDuration must be positive, but it is \(maximumAllowedSilenceDuration)", subprocessName: self.processName, subprocessId: processId, color: .red)
            return
        }
        
        log("Will track silences with timeout \(maximumAllowedSilenceDuration)", subprocessName: self.processName, subprocessId: processId, color: .boldBlue)
        
        let timer = DispatchSource.makeTimerSource(queue: silenceTrackingTimerQueue)
        timer.schedule(deadline: .now(), repeating: .seconds(1), leeway: .seconds(1))
        timer.setEventHandler { [weak self] in
            if let strongSelf = self {
                if Date().timeIntervalSince1970 - strongSelf.lastDataTimestamp > strongSelf.maximumAllowedSilenceDuration {
                    strongSelf.didDetectLongPeriodOfSilence()
                }
            }
        }
        timer.resume()
        silenceTrackingTimer = timer
    }
    
    private func didDetectLongPeriodOfSilence() {
        silenceTrackingTimer?.cancel()
        silenceTrackingTimer = nil
        log("Detected a long period of silence", subprocessName: self.processName, subprocessId: processId, color: .red)
        delegate?.processControllerDidNotReceiveAnyOutputWithinAllowedSilenceDuration(self)
    }
    
    private func openFileHandles() {
        if FileManager.default.createFile(atPath: stdoutContentsFile, contents: nil, attributes: [:]),
            let stdoutHandle = FileHandle(forWritingAtPath: stdoutContentsFile)
        {
            self.stdoutHandle = stdoutHandle
            log("Will store stdout output at: \(stdoutContentsFile)", subprocessName: self.processName, subprocessId: processId, color: .blue)
        } else {
            log("WARNING: Will not store stdout output at file, failed to open a file handle", color: .yellow)
        }
        if FileManager.default.createFile(atPath: stderrContentsFile, contents: nil, attributes: [:]),
            let stderrHandle = FileHandle(forWritingAtPath: stderrContentsFile)
        {
            log("Will store stderr output at: \(stderrContentsFile)", subprocessName: self.processName, subprocessId: processId, color: .blue)
            self.stderrHandle = stderrHandle
        } else {
            log("WARNING: Will not store stderr output at file, failed to open a file handle", color: .yellow)
        }
    }
    
    private func closeFileHandles() {
        stdoutHandle?.closeFile()
        stdoutHandle = nil
        stderrHandle?.closeFile()
        stderrHandle = nil
    }
    
    // MARK: - Processing Output
    
    private func setUpProcessListening() {
        storeStdForProcess(
            stdoutContentsFile,
            pipeAssigningClosure: { process.standardOutput = $0 }) { [weak self] in
                if let strongSelf = self {
                    strongSelf.stdoutHandle?.write($0)
                    strongSelf.delegate?.processController(strongSelf, newStdoutData: $0)
                }
            }
        
        storeStdForProcess(
            stderrContentsFile,
            pipeAssigningClosure: { process.standardError = $0 }) { [weak self] in
                if let strongSelf = self {
                    strongSelf.stderrHandle?.write($0)
                    strongSelf.delegate?.processController(strongSelf, newStderrData: $0)
                }
            }
    }
    
    private func storeStdForProcess(_ path: String, pipeAssigningClosure: (Pipe) -> (), onNewData: @escaping (Data) -> ()) {
        if FileManager.default.createFile(atPath: path, contents: nil, attributes: [:]),
            let storageHandle = FileHandle(forWritingAtPath: path) {
            let pipe = Pipe()
            pipeAssigningClosure(pipe)
            
            let pipeHandle = pipe.fileHandleForReading
            pipeHandle.waitForDataInBackgroundAndNotify()
            
            var observer: NSObjectProtocol?
            observer = NotificationCenter.default.addObserver(
            forName: NSNotification.Name.NSFileHandleDataAvailable, object: pipeHandle, queue: nil) { [weak self] _ in
                let data = pipeHandle.availableData
                if data.isEmpty {
                    storageHandle.closeFile()
                    if let observer = observer {
                        NotificationCenter.default.removeObserver(observer)
                    }
                }
                storageHandle.write(data)
                pipeHandle.waitForDataInBackgroundAndNotify()
                onNewData(data)
                self?.didProcessDataFromProcess()
            }
        }
    }
    
    private func didProcessDataFromProcess() {
        lastDataTimestamp = Date().timeIntervalSince1970
    }
}
