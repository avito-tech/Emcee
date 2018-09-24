import Foundation

class StdInToStdOutStreamer {
    public init() {}
    
    public func run() {
        print("stdin-to-stdout-streamer started!")
        while true {
            let stdinData = FileHandle.standardInput.availableData
            guard let string = String(data: stdinData, encoding: .utf8) else { break }
            guard let outputData = "stdin: \(string)\n".data(using: .utf8) else { break }
            FileHandle.standardOutput.write(outputData)
            fsync(FileHandle.standardOutput.fileDescriptor)
            
            if string.contains("bye") {
                break
            }
        }
    }
}

//uncomment_from_tests StdInToStdOutStreamer().run()
