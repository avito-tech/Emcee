@testable import Graphite
import IO
import Models
import XCTest

final class GraphiteClientTests: XCTestCase {
    func disabled___test___simple_use_case() throws {
        let stream = EasyOutputStream(
            outputStreamProvider: NetworkSocketOutputStreamProvider(host: "host", port: 65432),
            batchSize: 1024,
            errorHandler: { sender, error in
                XCTFail("Unexpected error: \(error)")
            },
            streamEndHandler: { _ in }
        )
        try stream.open()
        
        let client = GraphiteClient(easyOutputStream: stream)
        try client.send(path: ["some", "test", "metric"], value: 12.767, timestamp: Date())
        
        XCTAssertEqual(stream.waitAndClose(timeout: 5), .successfullyFlushedInTime)
    }
}
