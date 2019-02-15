import Foundation
import IO

final class FakeInMemoryOutputStreamProvider: OutputStreamProvider {
    let stream = OutputStream(toMemory: ())
    
    func createOutputStream() throws -> OutputStream {
        return stream
    }
}
