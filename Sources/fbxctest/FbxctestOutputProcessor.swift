import Ansi
import Foundation
import LocalHostDeterminer
import Logging
import ProcessController
import Timer

public final class FbxctestOutputProcessor: ProcessControllerDelegate {
    private let processController: ProcessController
    private let simulatorId: String
    private let eventsListener: FbXcTestEventsListener
    private let singleTestMaximumDuration: TimeInterval
    private var testHangTrackingTimer: DispatchBasedTimer?
    private let newLineByte = UInt8(10)
    private static let logDateStampLength = NSLogLikeLogEntryTextFormatter.logDateFormatter.string(from: Date()).count

    public init(
        subprocess: Subprocess,
        simulatorId: String,
        singleTestMaximumDuration: TimeInterval,
        onTestStarted: @escaping ((FbXcTestStartedEvent) -> ()),
        onTestStopped: @escaping ((FbXcTestEventPair) -> ())
        )
        throws
    {
        self.simulatorId = simulatorId
        self.singleTestMaximumDuration = singleTestMaximumDuration
        self.eventsListener = FbXcTestEventsListener(onTestStarted: onTestStarted, onTestStopped: onTestStopped)
        self.processController = try ProcessController(subprocess: subprocess)
        self.processController.delegate = self
    }
    
    public func processOutputAndWaitForProcessTermination() {
        startMonitoringForHangs()
        processController.startAndListenUntilProcessDies()
    }
    
    public var testEventPairs: [FbXcTestEventPair] {
        return eventsListener.allEventPairs
    }
    
    public var processId: Int32 {
        return processController.processId
    }
    
    // MARK: - Hang detection
    
    public func processControllerDidNotReceiveAnyOutputWithinAllowedSilenceDuration(_ sender: ProcessController) {
        eventsListener.timeoutDueToSilence()
        processController.interruptAndForceKillIfNeeded()
    }

    private func startMonitoringForHangs() {
        guard singleTestMaximumDuration > 0 else {
            log_fbxctest("Can't track hangs as singleTestMaximumDuration must be positive, but it is \(singleTestMaximumDuration)", processId)
            return
        }
        
        log_fbxctest("Will track long running tests with timeout \(singleTestMaximumDuration)", processId)
        
        testHangTrackingTimer = DispatchBasedTimer.startedTimer(repeating: .seconds(1), leeway: .seconds(1)) { [weak self] _ in
            guard let strongSelf = self else { return }
            guard let lastTestStartedEvent = strongSelf.eventsListener.lastStartedButNotFinishedTestEventPair?.startEvent else { return }
            if Date().timeIntervalSince1970 - lastTestStartedEvent.timestamp > strongSelf.singleTestMaximumDuration {
                strongSelf.didDetectLongRunningTest()
            }
        }
    }
    
    private func didDetectLongRunningTest() {
        if let testStartedEvent = eventsListener.lastStartedButNotFinishedTestEventPair?.startEvent {
            log_fbxctest("Detected a long running test: \(testStartedEvent.testName)", processId)
            eventsListener.longRunningTest()
        }
        processController.interruptAndForceKillIfNeeded()
    }
    
    // MARK: - stdout Processing
    
    private var notParsedEventDataPerProcess = [Int32: Data]()
    
    public func processController(_ sender: ProcessController, newStdoutData data: Data) {
        let joinedData: Data
        if let processData = notParsedEventDataPerProcess[processId] {
            joinedData = processData + data
        } else {
            joinedData = data
        }
        notParsedEventDataPerProcess.removeValue(forKey: processId)
        
        let possibleEvents = joinedData.split(separator: newLineByte)
        
        var notProcessedData = Data()
        possibleEvents.forEach { eventData in
            if !self.processSingleLiveEvent(data: eventData, processId: processId) {
                notProcessedData.append(eventData)
            }
        }
        if !notProcessedData.isEmpty {
            notParsedEventDataPerProcess[processId] = notProcessedData
        }
    }
    
    private func processSingleLiveEvent(data: Data, processId: Int32) -> Bool {
        let decoder = JSONDecoder()
        
        guard let fbxctestEvent = try? decoder.decode(FbXcTestEvent.self, from: data) else {
            return false
        }
        
        switch fbxctestEvent.event {
        case .testStarted:
            if let result = try? decoder.decode(FbXcTestStartedEvent.self, from: data)
                .withProcessId(newProcessId: processId)
                .withSimulatorId(newSimulatorId: simulatorId)
            {
                eventsListener.testStarted(result)
                return true
            }
        case .testFinished:
            if let result = try? decoder.decode(FbXcTestFinishedEvent.self, from: data) {
                eventsListener.testFinished(result)
                return true
            }
        case .testPlanFinished:
            if let result = try? decoder.decode(FbXcTestPlanFinishedEvent.self, from: data) {
                eventsListener.testPlanFinished(result)
                return true
            }
        case .testPlanError:
            if let result = try? decoder.decode(FbXcTestPlanErrorEvent.self, from: data) {
                eventsListener.testPlanError(result)
                return true
            }
        case .didCopyTestArtifact:
            return true
        case .osLogSaved:
            return true
        case .runnerAppLogSaved:
            return true
        case .testDetectedDebugger:
            return true
        case .testIsWaitingForDebugger:
            return true
        case .testOutput:
            return true
        case .testPlanStarted:
            return true
        case .testSuiteFinished:
            return true
        case .testSuiteStarted:
            return true
        case .videoRecordingFinished:
            return true
        }
        
        if let event = String(data: data, encoding: .utf8) {
            log_fbxctest("WARNING: unprocessed event: " + event, processId)
        }
        return true
    }
    
    // MARK: - stderr Processing
    
    public func processController(_ sender: ProcessController, newStderrData data: Data) {
        let possibleEvents = data.split(separator: newLineByte)
        possibleEvents.forEach { eventData in
            self.processSingleStdErrLiveEvent(data: eventData, processId: processId)
        }
    }
    
    private func processSingleStdErrLiveEvent(data: Data, processId: Int32) {
        guard let stringEvent = String(data: data, encoding: .utf8) else { return }
        
        // extract the date stamp from log event
        let contents: String
        let prefix = String(stringEvent.prefix(FbxctestOutputProcessor.logDateStampLength))
        if NSLogLikeLogEntryTextFormatter.logDateFormatter.date(from: prefix) != nil {
            contents = String(stringEvent.dropFirst(FbxctestOutputProcessor.logDateStampLength))
        } else {
            contents = stringEvent
        }
        processStdErrEventContents(contents, processId: processId)
    }
    
    private func processStdErrEventContents(_ contents: String, processId: Int32) {
        let decoder = JSONDecoder()
        guard let possibleJSONData = contents.data(using: .utf8),
            let genericError = try? decoder.decode(FbXcGenericErrorEvent.self, from: possibleJSONData) else {
                return
        }
        
        if genericError.domain == "com.facebook.XCTestBootstrap" {
            eventsListener.errorDuringTest(genericError)
        }
        
        if genericError.domain == "com.facebook.FBControlCore",
            let errorText = genericError.text,
            errorText.hasPrefix("Bundle Name (null) is not a String") {
            // skip
        } else if genericError.domain == "com.facebook.FBControlCore",
            let errorText = genericError.text,
            errorText.hasPrefix("Application with bundle id "), errorText.hasSuffix(" is not installed") {
            // skip
        } else if genericError.domain == "com.facebook.FBControlCore",
            let errorText = genericError.text,
            errorText.hasPrefix("File Handle is not open for reading") {
            // skip
        } else if genericError.domain == "com.facebook.FBTestError",
            let errorText = genericError.text,
            errorText.hasPrefix("A shim directory was expected at") {
            // skip
        } else {
            log_fbxctest(contents, processId)
        }
    }
}

private func log_fbxctest(_ text: String, _ fbxctestProcessId: Int32) {
    Logger.verboseDebug(
        text,
        subprocessInfo: SubprocessInfo(
            subprocessId: fbxctestProcessId,
            subprocessName: "fbxctest"
        )
    )
}
