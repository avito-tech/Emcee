import DateProvider
import Dispatch
import Extensions
import FileSystem
import Foundation
import Logging
import LoggingSetup
import PathLib
import Timer

public final class DefaultProcessController: ProcessController, CustomStringConvertible {
    public let subprocess: Subprocess
    public let processName: String
    public private(set) var processId: Int32 = 0
    
    private let automaticManagementItemControllers: [AutomaticManagementItemController]
    private let fileSystem: FileSystem
    let listenerQueue = DispatchQueue(label: "DefaultProcessController.listenerQueue")
    private let openPipeFileHandleGroup = DispatchGroup()
    private let process: Process
    private let processTerminationQueue = DispatchQueue(label: "DefaultProcessController.processTerminationQueue")
    private var automaticManagementTrackingTimer: DispatchBasedTimer?
    
    private var didInitiateKillOfProcess = false
    private var didStartProcess = false
    private var signalListeners = [ListenerWrapper<SignalListener>]()
    private var startListeners = [ListenerWrapper<StartListener>]()
    private var stderrListeners = [ListenerWrapper<StderrListener>]()
    private var stdoutListeners = [ListenerWrapper<StdoutListener>]()
    private var terminationListeners = [ListenerWrapper<TerminationListener>]()
    
    private final class ListenerWrapper<T> {
        let uuid: UUID
        let listener: T

        init(uuid: UUID, listener: T) {
            self.uuid = uuid
            self.listener = listener
        }
    }
    
    public init(
        dateProvider: DateProvider,
        fileSystem: FileSystem,
        subprocess: Subprocess
    ) throws {
        automaticManagementItemControllers = subprocess.automaticManagement.items.map { item in
            AutomaticManagementItemController(dateProvider: dateProvider, item: item)
        }
        
        let arguments = try subprocess.arguments.map { try $0.stringValue() }
        processName = arguments.elementAtIndex(0, "First element is path to executable").lastPathComponent
        process = try DefaultProcessController.createProcess(
            fileSystem: fileSystem,
            arguments: arguments,
            environment: subprocess.environment,
            workingDirectory: subprocess.workingDirectory
        )
        
        let logFolder = try fileSystem.folderForStoringLogs(processName: processName)
        let uniqueString = ProcessInfo.processInfo.globallyUniqueString
        self.subprocess = subprocess.byRedefiningOutput {
            $0.byRedefiningIfNotSet(
                stdoutOutputPath: logFolder.appending(component: uniqueString + "_stdout.log"),
                stderrOutputPath: logFolder.appending(component: uniqueString + "_stderr.log")
            )
        }
        self.fileSystem = fileSystem
        
        try setUpProcessListening()
    }
    
    private static func createProcess(
        fileSystem: FileSystem,
        arguments: [String],
        environment: [String: String],
        workingDirectory: AbsolutePath
    ) throws -> Process {
        let pathToExecutable = AbsolutePath(arguments.elementAtIndex(0, "Path to executable"))
        
        let executableProperties = fileSystem.properties(forFileAtPath: pathToExecutable)
        
        guard try executableProperties.isExecutable() else {
            throw ProcessControllerError.fileIsNotExecutable(path: pathToExecutable)
        }
        
        let process = Process()
        process.launchPath = pathToExecutable.pathString
        process.arguments = Array(arguments.dropFirst())
        process.environment = environment
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
            self.processTerminated()
        }
        processId = process.processIdentifier
        OrphanProcessTracker().storeProcessForCleanup(pid: processId, name: processName)
        Logger.debug("Started process \(processId)", subprocessInfo)
        startAutomaticManagement()

        listenerQueue.async {
            for listenerWrapper in self.startListeners {
                let unsubscriber: Unsubscribe = {
                    self.listenerQueue.async {
                        self.startListeners.removeAll { $0.uuid == listenerWrapper.uuid }
                    }
                }
                listenerWrapper.listener(self, unsubscriber)
            }
        }
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
    
    public func send(signal: Int32) {
        listenerQueue.async {
            for listenerWrapper in self.signalListeners {
                let unsubscriber: Unsubscribe = {
                    self.listenerQueue.async {
                        self.signalListeners.removeAll { $0.uuid == listenerWrapper.uuid }
                    }
                }
                listenerWrapper.listener(self, signal, unsubscriber)
            }
            
            Logger.debug("Signalling \(signal)", self.subprocessInfo)
            kill(-self.processId, signal)
        }
    }
    
    public func terminateAndForceKillIfNeeded() {
        attemptToKillProcess { process in
            Logger.debug("Terminating the process", subprocessInfo)
            send(signal: SIGTERM)
        }
    }
    
    public func interruptAndForceKillIfNeeded() {
        attemptToKillProcess { process in
            Logger.debug("Interrupting the process", subprocessInfo)
            send(signal: SIGINT)
        }
    }
    
    public func onStart(listener: @escaping StartListener) {
        startListeners.append(ListenerWrapper(uuid: UUID(), listener: listener))
    }
    
    public func onStdout(listener: @escaping StdoutListener) {
        stdoutListeners.append(ListenerWrapper(uuid: UUID(), listener: listener))
    }
    
    public func onStderr(listener: @escaping StderrListener) {
        stderrListeners.append(ListenerWrapper(uuid: UUID(), listener: listener))
    }
    
    public func onSignal(listener: @escaping SignalListener) {
        signalListeners.append(ListenerWrapper(uuid: UUID(), listener: listener))
    }
    
    public func onTermination(listener: @escaping TerminationListener) {
        terminationListeners.append(ListenerWrapper(uuid: UUID(), listener: listener))
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
            send(signal: SIGKILL)
            
            signalListeners.removeAll()
            startListeners.removeAll()
            stderrListeners.removeAll()
            stdoutListeners.removeAll()
        }
    }
    
    private func processTerminated() {
        Logger.debug("Process terminated", subprocessInfo)
        
        listenerQueue.async {
            for listenerWrapper in self.terminationListeners {
                let unsubscriber: Unsubscribe = {
                    self.listenerQueue.async {
                        self.signalListeners.removeAll { $0.uuid == listenerWrapper.uuid }
                    }
                }
                listenerWrapper.listener(self, unsubscriber)
            }
        }
    }
    
    // MARK: - Hang Monitoring
    
    private func startAutomaticManagement() {
        Logger.debug("Will start automatic process management", subprocessInfo)
        
        automaticManagementTrackingTimer = DispatchBasedTimer.startedTimer(repeating: .seconds(1), leeway: .seconds(1)) { [weak self] timer in
            guard let strongSelf = self else { return timer.stop() }
            
            strongSelf.automaticManagementItemControllers.forEach { $0.fireEventIfNecessary(processController: strongSelf) }
        }
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
    
    private func setUpProcessListening() throws {
        storeStdForProcess(
            path: try subprocess.standardStreamsCaptureConfig.stdoutOutputPath(),
            onError: { message in
                Logger.warning("Will not store stdout output: \(message)", subprocessInfo)
            },
            pipeAssigningClosure: { pipe in
                self.process.standardOutput = pipe
                self.openPipeFileHandleGroup.enter()
            },
            onNewData: didReceiveStdout,
            onEndOfData: {
                self.listenerQueue.async {
                    self.openPipeFileHandleGroup.leave()
                }
            }
        )
        
        storeStdForProcess(
            path: try subprocess.standardStreamsCaptureConfig.stderrOutputPath(),
            onError: { message in
                Logger.warning("Will not store stderr output: \(message)", subprocessInfo)
            },
            pipeAssigningClosure: { pipe in
                self.process.standardError = pipe
                self.openPipeFileHandleGroup.enter()
            },
            onNewData: didReceiveStderr,
            onEndOfData: {
                self.listenerQueue.async {
                    self.openPipeFileHandleGroup.leave()
                }
            }
        )
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
        for controller in automaticManagementItemControllers {
            controller.processReportedActivity()
        }
    }
}

