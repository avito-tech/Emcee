import Foundation
import LocalHostDeterminer
import Logging
import ProcessController
import Runner
import RunnerModels
import Timer

public final class FbxctestOutputProcessor: TestRunnerInvocation {
    private let processController: ProcessController
    private let eventsListener: FbXcTestEventsListener
    private let newLineByte = UInt8(10)
    private static let logDateStampLength = NSLogLikeLogEntryTextFormatter.logDateFormatter.string(from: Date()).count

    public init(
        onStreamOpen: @escaping () -> (),
        onTestStarted: @escaping ((TestName) -> ()),
        onTestStopped: @escaping ((TestStoppedEvent) -> ()),
        onStreamClose: @escaping () -> (),
        processController: ProcessController
    ) throws {
        self.eventsListener = FbXcTestEventsListener(onTestStarted: onTestStarted, onTestStopped: onTestStopped)
        self.processController = processController
        
        processController.onStart { _, _ in onStreamOpen() }
        processController.onStdout { [weak self] (sender, data, unsubscriber) in
            guard let strongSelf = self else { return unsubscriber() }
            strongSelf.processController(sender, newStdoutData: data)
        }
        processController.onStderr { [weak self] (sender, data, unsubscriber) in
            guard let strongSelf = self else { return unsubscriber() }
            strongSelf.processController(sender, newStderrData: data)
        }
        processController.onTermination { _, _ in onStreamClose() }
    }
    
    public func startExecutingTests() -> TestRunnerRunningInvocation {
        processController.start()
        
        return ProcessControllerWrappingTestRunnerInvocation(processController: processController)
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
        let possibleJSONData = Data(contents.utf8)
        guard let genericError = try? decoder.decode(FbXcGenericErrorEvent.self, from: possibleJSONData) else {
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
