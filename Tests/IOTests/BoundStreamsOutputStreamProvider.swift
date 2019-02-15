import Foundation
import IO

final class BoundStreamsOutputStreamProvider: OutputStreamProvider {
    
    let inputStream: InputStream
    let outputStream: OutputStream
    
    public init(bufferSize: Int = 1024) {
        var boundInputStream: InputStream?
        var boundOutputStream: OutputStream?
        Stream.getBoundStreams(
            withBufferSize: bufferSize,
            inputStream: &boundInputStream,
            outputStream: &boundOutputStream
        )
        inputStream = boundInputStream!
        outputStream = boundOutputStream!
    }
    
    func createOutputStream() throws -> OutputStream {
        return outputStream
    }
}
