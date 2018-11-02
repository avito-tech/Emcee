import Foundation

class StdInToStdOutStreamer {
    public init() {}
    
    public func run() {
        FileHandle.standardOutput.write("stdin-to-stdout-streamer started!".data(using: .utf8)!)
        
        while true {
            let stdinData = FileHandle.standardInput.availableData
            guard let string = String(data: stdinData, encoding: .utf8) else { break }
            guard let outputData = string.data(using: .utf8) else { break }
            FileHandle.standardOutput.write(outputData)
            fsync(FileHandle.standardOutput.fileDescriptor)
            
            if string.contains("bye") {
                break
            }
        }
    }
}

// Swift does not allow to have a top level code statements unless the file is named main.swift.
// We use this file as a simple program that we invoke via `swift StdInToStdOutStreamer.swift` right from unit test
// To make top level code work, we copy this file and uncomment the line below, and then we invoke this code
// by calling `swift`.

//uncomment_from_tests StdInToStdOutStreamer().run()
