import Foundation

enum FileState {
    case open(FileHandle)
    case closed
    
    var openedFileHandle: FileHandle? {
        switch self {
        case .open(let handle): return handle
        case .closed: return nil
        }
    }
    
    mutating func close() {
        switch self {
        case .open(let handle):
            handle.closeFile()
            self = .closed
        case .closed:
            break
        }
    }
}
