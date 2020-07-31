import Foundation

extension FileHandle {
    func seekToOffsetFromEnd(offset: UInt64) {
        let eofOffset = seekToEndOfFile()
        let targetOffset = (offset > eofOffset) ? 0 : (eofOffset - offset)
        seek(toFileOffset: targetOffset)
    }
    
    func stream(toFileHandle: FileHandle, chunkSize: Int = 4096) {
        while true {
            let data = readData(ofLength: chunkSize)
            if data.isEmpty { break }
            toFileHandle.write(data)
        }
    }
}
