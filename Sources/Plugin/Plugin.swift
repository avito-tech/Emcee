import Basic
import Dispatch
import EventBus
import Foundation
import JSONStream
import Logging
import Models
import SynchronousWaiter

/// Allows the plugin to track `PluginEvent`s from the main process using the provided `EventBus`.
public final class Plugin {
    private let eventBus: EventBus
    private let inputFileHandle: FileHandle
    private let jsonReaderQueue = DispatchQueue(label: "ru.avito.Plugin.jsonReaderQueue")
    private let stdinReadQueue = DispatchQueue(label: "ru.avito.Plugin.stdinReadQueue")
    private let jsonInputStream = BlockingArrayBasedJSONStream()
    private let jsonStreamToEventBusAdapter: JSONStreamToEventBusAdapter
    private var jsonStreamHasFinished = false
    
    /// Creates a Plugin class that can be used to broadcast the PluginEvents from the main process
    /// into the provided EventBus.
    /// - Parameters:
    ///     - eventBus:             The event bus which will receive the events from the main process
    ///     - inputFileHandle:      The file handle to read from
    public init(
        eventBus: EventBus,
        inputFileHandle: FileHandle = FileHandle.standardInput)
    {
        self.eventBus = eventBus
        self.inputFileHandle = inputFileHandle
        self.jsonStreamToEventBusAdapter = JSONStreamToEventBusAdapter(eventBus: eventBus)
    }
    
    public func streamPluginEvents() {
        automaticallyInterruptOnTearDown()
        
        let jsonReader = JSONReader(inputStream: jsonInputStream, eventStream: jsonStreamToEventBusAdapter)
        readDataInBackground()
        jsonReaderQueue.async {
            do {
                log("Starting JSON stream parser")
                try jsonReader.start()
            } catch {
                self.jsonStreamHasFinished = true
                log("JSON stream error: \(error)", color: .red)
            }
            log("JSON stream parser finished")
        }
    }
    
    public func join() {
        try? SynchronousWaiter.waitWhile {
            return jsonStreamHasFinished == false
        }
    }
    
    private func automaticallyInterruptOnTearDown() {
        let tearDownHandler = TearDownHandler { [weak self] in
            self?.interrupt()
        }
        eventBus.add(stream: tearDownHandler)
    }
    
    private func interrupt() {
        eventBus.uponDeliveryOfAllEvents {
            self.jsonInputStream.willProvideMoreData = false
            self.jsonStreamHasFinished = true
        }
    }
    
    private func readDataInBackground() {
        stdinReadQueue.async {
            while self.jsonStreamHasFinished == false {
                let data = self.inputFileHandle.availableData
                if data.isEmpty {
                    self.onEndOfData()
                    break
                } else {
                    self.onNewData(data: data)
                }
            }
        }
    }
    
    private func onNewData(data: Data) {
        jsonInputStream.append(data)
    }
    
    private func onEndOfData() {
        jsonInputStream.willProvideMoreData = false
    }
}
