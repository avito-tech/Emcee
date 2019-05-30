import Basic
import Dispatch
import Foundation
import JSONStream
import Logging
import ProcessController

public final class FbsimctlOutputProcessor: ProcessControllerDelegate, JSONReaderEventStream {
    private let processController: ProcessController
    private var receivedEvents = [FbSimCtlEventCommonFields]()
    private let jsonStream = BlockingArrayBasedJSONStream()
    private let decoder = JSONDecoder()
    private let jsonReaderQueue = DispatchQueue(label: "ru.avito.FbsimctlOutputProcessor.jsonReaderQueue")
    
    public init(processController: ProcessController) {
        self.processController = processController
        processController.delegate = self
    }
    
    public func waitForEvent(type: FbSimCtlEventType, name: FbSimCtlEventName, timeout: TimeInterval) throws {
        let startTime = Date().timeIntervalSinceReferenceDate
        startProcessingJSONStream()
        defer { jsonStream.willProvideMoreData = false }
        processController.start()
        while processController.isProcessRunning, !checkDidReceiveEvent(type: type, name: name) {
            guard Date().timeIntervalSinceReferenceDate - startTime < timeout else {
                throw FbsimctlEventWaitError.timeoutOccured(name, type)
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.5))
        }
        if !checkDidReceiveEvent(type: type, name: name) {
            throw FbsimctlEventWaitError.processTerminatedWithoutEvent(name, type)
        }
    }
    
    // MARK: - Private
    
    private func checkDidReceiveEvent(type: FbSimCtlEventType, name: FbSimCtlEventName) -> Bool {
        return !receivedEvents.filter { $0.name == name && $0.type == type }.isEmpty
    }
    
    private func startProcessingJSONStream() {
        jsonReaderQueue.async {
            let reader = JSONReader(inputStream: self.jsonStream, eventStream: self)
            do {
                try reader.start()
            } catch {
                Logger.error("JSON stream processing failed: \(error). Context: \(reader.collectedScalars)")
            }
        }
    }
    
    private func processSingleLiveEvent(_ scalars: [Unicode.Scalar]) {
        var string = String()
        string.unicodeScalars.append(contentsOf: scalars)
        guard let eventData = string.data(using: .utf8) else {
            Logger.warning("Failed to convert JSON string to data: '\(string)'")
            return
        }
        processSingleLiveEvent(eventData: eventData, dataStringRepresentation: string)
    }
    
    private func processSingleLiveEvent(eventData: Data, dataStringRepresentation: String) {
        if let event = try? decoder.decode(FbSimCtlEventWithStringSubject.self, from: eventData) {
            Logger.verboseDebug(String(describing: event), subprocessInfo: SubprocessInfo(subprocessId: processController.processId, subprocessName: processController.processName))
            receivedEvents.append(event)
        } else {
            do {
                let event = try decoder.decode(FbSimCtlEvent.self, from: eventData)
                Logger.verboseDebug(String(describing: event), subprocessInfo: SubprocessInfo(subprocessId: processController.processId, subprocessName: processController.processName))
                receivedEvents.append(event)
            } catch {
                Logger.warning("Failed to parse event: '\(dataStringRepresentation)': \(error)", subprocessInfo: SubprocessInfo(subprocessId: processController.processId, subprocessName: processController.processName))
            }
        }
    }
    
    // MARK: - JSONReaderEventStream
    
    public func newArray(_ array: NSArray, scalars: [Unicode.Scalar]) {
        processSingleLiveEvent(scalars)
    }
    
    public func newObject(_ object: NSDictionary, scalars: [Unicode.Scalar]) {
        processSingleLiveEvent(scalars)
    }
    
    // MARK: - ProcessControllerDelegate
    
    public func processController(_ sender: ProcessController, newStdoutData data: Data) {
        jsonStream.append(data)
    }
    
    public func processController(_ sender: ProcessController, newStderrData data: Data) {
        if let string = String(data: data, encoding: .utf8) {
            Logger.verboseDebug("stderr: " + string, subprocessInfo: SubprocessInfo(subprocessId: processController.processId, subprocessName: processController.processName))
        }
    }
    
    public func processControllerDidNotReceiveAnyOutputWithinAllowedSilenceDuration(_ sender: ProcessController) {
        sender.interruptAndForceKillIfNeeded()
    }
}
