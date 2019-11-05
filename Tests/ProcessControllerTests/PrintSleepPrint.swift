import Foundation

class PrintSleepPrint {
    public init() {}
    
    public func run() {
        let fileHandle: FileHandle
        
        if ProcessInfo.processInfo.environment["EMCEE_TEST_USE_STDERR"] == "true" {
            fileHandle = FileHandle.standardError
        } else {
            fileHandle = FileHandle.standardOutput
        }
        
        fileHandle.write("Print".data(using: .utf8)!)
        Thread.sleep(forTimeInterval: 1.0)
        fileHandle.write("Finished".data(using: .utf8)!)
    }
}

//uncomment_from_tests PrintSleepPrint().run()
