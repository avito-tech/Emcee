import Foundation
import Models

public final class EasyOutputStream: NSObject, StreamDelegate {
    
    public typealias ErrorHandler = (EasyOutputStream, EasyOutputStreamError) -> ()
    public typealias StreamEndHandler = (EasyOutputStream) -> ()
    
    public enum TearDownResult: Equatable {
        case successfullyFlushedInTime
        case flushTimeout
    }
    
    /// Instance that can create output streams upon request.
    private let outputStreamProvider: OutputStreamProvider
    
    /// Runtime stream error handler.
    private let errorHandler: ErrorHandler
    
    /// Stream end handler is called when stream concludes writing data. After this stream will be closed.
    private let streamEndHandler: StreamEndHandler
    
    /// Queue used to call error handler.
    private let handlerQueue = DispatchQueue(label: "ru.avito.emcee.EasyOutputStream.errorQueue")
    
    /// Indicator if stream is accepting new data or closing because of waitAndClose()
    private let acceptsNewData = AtomicValue<Bool>(false)
    
    /// A size of single write attemp.
    private let batchSize: Int
    
    /// An indication that we should send new data immediately to output stream instead of waiting for StreamDelegate event.
    /// Happens if we have zero data to write to output stream. Then, to wake up StreamDelegate flow, we must send
    /// data to stream directly.
    private var needsToSendDataToStreamDirectly = AtomicValue<Bool>(false)
    
    /// Thread that owns a run loop which is used by output stream.
    private var thread: Thread?
    
    /// Buffer is used to enqueue data to be sent into output stream.
    private let buffer = AtomicCollection<Data>(Data())

    public init(
        outputStreamProvider: OutputStreamProvider,
        batchSize: Int = 1024,
        errorHandler: @escaping ErrorHandler,
        streamEndHandler: @escaping StreamEndHandler)
    {
        self.outputStreamProvider = outputStreamProvider
        self.batchSize = batchSize
        self.errorHandler = errorHandler
        self.streamEndHandler = streamEndHandler
    }
    
    /// Closes previously opened streams, and opens a new stream.
    public func open() throws {
        terminateStreamThread()
        
        let outputStream = try outputStreamProvider.createOutputStream()
        thread = Thread(target: self, selector: #selector(handleStream(outputStream:)), object: outputStream)
        thread?.name = "ru.avito.emcee.EasyOutputStream"
        thread?.start()
        
        acceptsNewData.set(true)
    }
    
    /// Immediately closes the output stream and erases buffer.
    public func close() {
        acceptsNewData.set(false)
        buffer.set(Data())
        terminateStreamThread()
    }
    
    /// Waits given time to deliver buffered data and then closes the output stream.
    /// - Parameter timeout: Time for writing all enqueued data.
    /// - Returns: `true` if torn down within limit, `false` on timeout.
    public func waitAndClose(timeout: TimeInterval) -> TearDownResult {
        acceptsNewData.set(false)
        wakeUpThreadsRunloop()
        
        let result = buffer.waitWhen(
            count: 0,
            before: Date().addingTimeInterval(timeout)
        )
        
        close()
        if result {
            return .successfullyFlushedInTime
        } else {
            return .flushTimeout
        }
    }
    
    /// Enqueues data to be sent via stream.
    public func enqueueWrite(data: Data) throws {
        guard acceptsNewData.currentValue() else {
            throw EasyOutputStreamError.streamClosed
        }
        
        guard !data.isEmpty else { return }
        
        _ = buffer.withExclusiveAccess { bytes in
            bytes.append(data)
        }
        
        wakeUpThreadsRunloop()
    }
    
    // MARK: - Stream handing
    
    @objc private func handleStream(outputStream: OutputStream) {
        outputStream.delegate = self
        outputStream.schedule(in: RunLoop.current, forMode: RunLoop.Mode.default)
        outputStream.open()
        
        while !Thread.current.isCancelled {
            RunLoop.current.run(mode: RunLoop.Mode.default, before: Date.distantFuture)
            writeDataIfEnqueuedOutOfDelegateEventIfNeeded(outputStream: outputStream)
        }
        
        outputStream.close()
        outputStream.remove(from: RunLoop.current, forMode: RunLoop.Mode.default)
        outputStream.delegate = nil
    }
    
    public func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        switch eventCode {
        case .openCompleted:
            break
        case .hasBytesAvailable:
            break
        case .hasSpaceAvailable:
            writeDataOnDelegateEvent(outputStream: aStream as! OutputStream)
        case .errorOccurred:
            if let streamError = aStream.streamError {
                handlerQueue.async {
                    self.errorHandler(self, EasyOutputStreamError.streamError(streamError))
                }
            }
            terminateStreamThread()
        case .endEncountered:
            handlerQueue.async {
                self.streamEndHandler(self)
            }
            terminateStreamThread()
        default:
            break
        }
    }
    
    /// Writes data and returns a number of bytes written. Should be called when stream has some space available.
    @discardableResult
    private func writeBufferedData(outputStream: OutputStream, numberOfBytes: Int) -> Int {
        var bytesWritten = 0
        _ = buffer.withExclusiveAccess { data in
            bytesWritten = data.withUnsafeBytes { bytes -> Int in
                outputStream.write(bytes, maxLength: min(numberOfBytes, data.count))
            }
            if bytesWritten > 0 {
                data = data.dropFirst(bytesWritten)
            }
        }
        return bytesWritten
    }
    
    private func writeDataOnDelegateEvent(outputStream: OutputStream) {
        if buffer.currentValue().isEmpty {
            needsToSendDataToStreamDirectly.set(true)
        } else {
            writeBufferedData(outputStream: outputStream, numberOfBytes: batchSize)
        }
    }
    
    private func writeDataIfEnqueuedOutOfDelegateEventIfNeeded(outputStream: OutputStream) {
        guard !buffer.currentValue().isEmpty else { return }
        
        if needsToSendDataToStreamDirectly.currentValue() {
            if outputStream.hasSpaceAvailable {
                writeBufferedData(outputStream: outputStream, numberOfBytes: 1)
            } else {
                errorHandler(self, EasyOutputStreamError.streamHasNoSpaceAvailable)
            }
            needsToSendDataToStreamDirectly.set(false)
        }
    }
    
    private func terminateStreamThread() {
        thread?.cancel()
        wakeUpThreadsRunloop()
        thread = nil
    }
    
    // MARK: - RunLoop Awaking
    
    private func wakeUpThreadsRunloop() {
        if let thread = thread {
            self.perform(#selector(wakeUpThreadRunloop_onThread), on: thread, with: nil, waitUntilDone: false)
        }
    }
    
    @objc private func wakeUpThreadRunloop_onThread() {
        // this method exists just to be able to wake up the runloop
    }
}
