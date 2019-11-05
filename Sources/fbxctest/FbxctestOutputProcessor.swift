import Ansi
import Foundation
import LocalHostDeterminer
import Logging
import Models
import ProcessController
import Timer

public final class FbxctestOutputProcessor {
    private let processController: ProcessController
    private let eventsListener: FbXcTestEventsListener
    private let singleTestMaximumDuration: TimeInterval
    private var testHangTrackingTimer: DispatchBasedTimer?
    private let newLineByte = UInt8(10)
    private static let logDateStampLength = NSLogLikeLogEntryTextFormatter.logDateFormatter.string(from: Date()).count

    public init(
        subprocess: Subprocess,
        singleTestMaximumDuration: TimeInterval,
        onTestStarted: @escaping ((TestName) -> ()),
        onTestStopped: @escaping ((TestStoppedEvent) -> ())
    ) throws {
        self.singleTestMaximumDuration = singleTestMaximumDuration
        self.eventsListener = FbXcTestEventsListener(onTestStarted: onTestStarted, onTestStopped: onTestStopped)
        self.processController = try DefaultProcessController(subprocess: subprocess)
    }
    
    public func processOutputAndWaitForProcessTermination() {
        processController.onSilence { [weak self] sender, unsubscriber in
            guard let strongSelf = self else { return unsubscriber() }
            strongSelf.eventsListener.timeoutDueToSilence()
        }
        processController.onStdout { [weak self] (sender, data, unsubscriber) in
            guard let strongSelf = self else { return unsubscriber() }
            strongSelf.processController(sender, newStdoutData: data)
        }
        processController.onStderr { [weak self] (sender, data, unsubscriber) in
            guard let strongSelf = self else { return unsubscriber() }
            strongSelf.processController(sender, newStderrData: data)
        }
        
        processController.start()
        startMonitoringForHangs()
        processController.waitForProcessToDie()
    }
    
    public var subprocess: Subprocess {
        return processController.subprocess
    }
    
    // MARK: - Hang detection

    private func startMonitoringForHangs() {
        guard singleTestMaximumDuration > 0 else {
            log_fbxctest("Can't track hangs as singleTestMaximumDuration must be positive, but it is \(singleTestMaximumDuration)")
            return
        }
        
        log_fbxctest("Will track long running tests with timeout \(singleTestMaximumDuration)")
        
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
            log_fbxctest("Detected a long running test: \(testStartedEvent.testName)")
            eventsListener.longRunningTest()
        }
        processController.interruptAndForceKillIfNeeded()
    }
    
    // MARK: - stdout Processing
    
    private var notParsedEventDataPerProcess = [Int32: Data]()
    
    private func processController(_ sender: ProcessController, newStdoutData data: Data) {
        let joinedData: Data
        if let processData = notParsedEventDataPerProcess[processController.processId] {
            joinedData = processData + data
        } else {
            joinedData = data
        }
        notParsedEventDataPerProcess.removeValue(forKey: processController.processId)
        
        let possibleEvents = joinedData.split(separator: newLineByte)
        
        var notProcessedData = Data()
        possibleEvents.forEach { eventData in
            if !self.processSingleLiveEvent(data: eventData, processId: processController.processId) {
                notProcessedData.append(eventData)
            }
        }
        if !notProcessedData.isEmpty {
            notParsedEventDataPerProcess[processController.processId] = notProcessedData
        }
    }
    
    private func processSingleLiveEvent(data: Data, processId: Int32) -> Bool {
        let decoder = JSONDecoder()
        
        guard let fbxctestEvent = try? decoder.decode(FbXcTestEvent.self, from: data) else {
            return false
        }
        
        switch fbxctestEvent.event {
        case .testStarted:
            if let result = try? decoder.decode(FbXcTestStartedEvent.self, from: data) {
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
            log_fbxctest("WARNING: unprocessed event: " + event)
        }
        return true
    }
    
    // MARK: - stderr Processing
    
    private func processController(_ sender: ProcessController, newStderrData data: Data) {
        let possibleEvents = data.split(separator: newLineByte)
        possibleEvents.forEach { eventData in
            self.processSingleStdErrLiveEvent(data: eventData, processId: processController.processId)
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
            log_fbxctest(contents)
        }
    }
    
    private func log_fbxctest(_ text: String) {
        Logger.verboseDebug(text, processController.subprocessInfo)
    }
}
