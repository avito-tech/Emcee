import Foundation

class FakeFileHandle: FileHandle {
    
    var isClosed = false
    var closeCounter = 0
    
    override func closeFile() {
        isClosed = true
        closeCounter += 1
    }
}
