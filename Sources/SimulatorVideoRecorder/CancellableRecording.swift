import Foundation

public protocol CancellableRecording {
    func stopRecording() -> String
}

public extension CancellableRecording {
    public func cancelAndDeleteRecordedFile() throws {
        let output = stopRecording()
        if FileManager.default.fileExists(atPath: output) {
            try FileManager.default.removeItem(atPath: output)
        }
    }
}
