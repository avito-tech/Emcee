import Foundation

public enum EasyOutputStreamError: Error, CustomStringConvertible {
    case streamClosed
    case streamError(Error)
    case streamHasNoSpaceAvailable
    
    public var description: String {
        switch self {
        case .streamError(let error):
            return "Stream error: \(error)"
        case .streamClosed:
            return "Can't send data because stream is closed or about to close."
        case .streamHasNoSpaceAvailable:
            return "Stream has no space available"
        }
    }
}
