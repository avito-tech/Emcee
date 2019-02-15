import Foundation
import IO

final class FakeBufferedOutputStreamProvider: OutputStreamProvider {
    let capacity: Int
    var data: Data

    public init(capacity: Int) {
        self.capacity = capacity
        self.data = Data(capacity: capacity)
    }
    
    lazy var stream: OutputStream = {
        return data.withUnsafeMutableBytes({ mutableBytes -> OutputStream in
            OutputStream(toBuffer: mutableBytes, capacity: capacity)
        })
    }()
    
    func createOutputStream() throws -> OutputStream {
        return stream
    }
}
