import Foundation

public protocol CancellableRecording {
    /// Stops recording and returns a path to a file where video is stored.
    func stopRecording() -> String
    
    /// Cancels recording and does not write any data to the file. Thus, does not return any path.
    func cancelRecording()
}
