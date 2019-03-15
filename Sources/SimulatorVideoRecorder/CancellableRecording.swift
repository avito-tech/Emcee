import Foundation

public protocol CancellableRecording {
    /// Stops recording and returns a path to a file where video is stored.
    func stopRecording() -> String
    
    /// Cancels recording and does not write any data to the file. Thus, does not return any path.
    func cancelRecording()
}

public extension CancellableRecording {
    /// TODO: remove, left for backwards compatibility
    public func cancelAndDeleteRecordedFile() throws {
        cancelRecording()
    }
}
