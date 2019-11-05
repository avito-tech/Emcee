import Foundation

class StdInToStdOutStreamer {
    public init() {}
    
    public func run() {
        write(string: "stdin-to-stdout-streamer started!", file: stdout)
        
        FileHandle.standardInput.readabilityHandler = { handler in
            let stdinData = handler.availableData
            if stdinData.isEmpty {
                FileHandle.standardInput.readabilityHandler = nil
            } else {
                guard let string = String(data: stdinData, encoding: .utf8) else { return }
                guard let outputData = string.data(using: .utf8) else { return }
                write(data: outputData, file: stdout)
                if string.contains("bye") {
                    FileHandle.standardInput.readabilityHandler = nil
                }
            }
        }
        
        while FileHandle.standardInput.readabilityHandler != nil {
            RunLoop.current.run(mode: .common, before: Date(timeIntervalSinceNow: 0.1))
        }
    }
}

func write(string: String, file: UnsafeMutablePointer<FILE>) {
    guard let data = string.data(using: .utf8) else { return }
    write(data: data, file: file)
}

func write(data: Data, file: UnsafeMutablePointer<FILE>) {
    data.withUnsafeBytes { (pointer: UnsafeRawBufferPointer) -> Void in
        let bytes = pointer.load(as: [Int8].self)
        fwrite(bytes, 1, data.count, file)
        fflush(file)
    }
}

//uncomment_from_tests StdInToStdOutStreamer().run()
