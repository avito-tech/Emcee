import IO
import XCTest

final class EasyOutputStreamTests: XCTestCase {
    
    let inMemoryOutputStreamProvider = FakeInMemoryOutputStreamProvider()
    
    let data = "hello world!".data(using: .utf8)!
    
    lazy var inMemoryStream = EasyOutputStream(
        outputStreamProvider: inMemoryOutputStreamProvider,
        batchSize: 1024,
        errorHandler: { _, _ in },
        streamEndHandler: { _ in }
    )
    
    func test___writing_to_stream() {
        XCTAssertNoThrow(
            try inMemoryStream.open()
        )
        
        XCTAssertNoThrow(
            try inMemoryStream.enqueueWrite(data: data)
        )
        
        XCTAssertEqual(
            inMemoryStream.waitAndClose(timeout: 5.0),
            .successfullyFlushedInTime
        )
        
        XCTAssertEqual(
            streamData(),
            data
        )
    }
    
    func test___writing_to_closing_stream___throws() {
        XCTAssertNoThrow(
            try inMemoryStream.open()
        )
        
        _ = inMemoryStream.waitAndClose(timeout: 0.0)
        XCTAssertThrowsError(
            try inMemoryStream.enqueueWrite(data: data)
        )
    }
    
    func test___writing_to_closed_stream___throws() {
        XCTAssertNoThrow(
            try inMemoryStream.open()
        )
        
        inMemoryStream.close()
        XCTAssertThrowsError(
            try inMemoryStream.enqueueWrite(data: data)
        )
    }
    
    func test___writing_to_never_opened_stream___throws() {
        XCTAssertThrowsError(
            try inMemoryStream.enqueueWrite(data: data)
        )
    }
    
    func test___when_reading_end_closes___invokes_end_of_stream_handler() {
        let outputStreamProvider = BoundStreamsOutputStreamProvider()
        outputStreamProvider.inputStream.open()
        
        let streamEndHandlerInvoked = expectation(description: "Invoked end of stream handler")
        
        let stream = EasyOutputStream(
            outputStreamProvider: outputStreamProvider,
            batchSize: 1024,
            errorHandler: { _, _ in },
            streamEndHandler: { _ in streamEndHandlerInvoked.fulfill() }
        )
        
        XCTAssertNoThrow(
            try stream.open()
        )
        XCTAssertNoThrow(
            try stream.enqueueWrite(data: data)
        )
        
        closeReadingEndAfterReadingSomeData(outputStreamProvider)
        
        wait(for: [streamEndHandlerInvoked], timeout: 5)
        stream.close()
    }
    
    func test___when_stream_error_occurs___invokes_stream_error_handler() {
        let outputStreamProvider = FakeBufferedOutputStreamProvider(capacity: 1)
        
        let streamErrorHandlerInvoked = expectation(description: "Invoked stream error handler")
        
        let stream = EasyOutputStream(
            outputStreamProvider: outputStreamProvider,
            batchSize: 1024,
            errorHandler: { _, _ in streamErrorHandlerInvoked.fulfill() },
            streamEndHandler: { _ in }
        )
        
        XCTAssertNoThrow(
            try stream.open()
        )
        XCTAssertNoThrow(
            try stream.enqueueWrite(data: data)
        )
        
        wait(for: [streamErrorHandlerInvoked], timeout: 5)
        stream.close()
    }
    
    private func streamData() -> Data {
        guard let streamData = inMemoryOutputStreamProvider.stream.property(forKey: .dataWrittenToMemoryStreamKey) as? Data else {
            XCTFail("Stream data has unexpected type")
            return Data()
        }
        return streamData
    }
    
    private func closeReadingEndAfterReadingSomeData(_ outputStreamProvider: BoundStreamsOutputStreamProvider) {
        var readData = Data(capacity: 1)
        _ = readData.withUnsafeMutableBytes { bytes -> Int in
            outputStreamProvider.inputStream.read(bytes, maxLength: 1)
        }
        outputStreamProvider.inputStream.close()
    }
}

