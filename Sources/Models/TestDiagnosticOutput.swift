import Foundation

public struct TestDiagnosticOutput {

    /** Absolute path to a file where a video recording of the running simulator should be stored. Optional, if missing, video won't be recorded. */
    public let videoOutputPath: String?
    
    /** Absolute path to a file where an os_log output should be stored. (os_log means Apple's unified logging system (https://developer.apple.com/documentation/os/logging) */
    public let oslogOutputPath: String?
    
    /** Absolute path to a file where stdout/stderr test output test should be stored. */
    public let testLogOutputPath: String?

    public init(runtime: String, videoOutputPath: String?, oslogOutputPath: String?, testLogOutputPath: String?) throws {
        self.videoOutputPath = videoOutputPath
        self.oslogOutputPath = try TestDiagnosticOutput.supportsOslogCapture(runtime) ? oslogOutputPath : nil
        self.testLogOutputPath = testLogOutputPath
    }
    
    public init() {
        self.videoOutputPath = nil
        self.oslogOutputPath = nil
        self.testLogOutputPath = nil
    }
    
    public static let nullOutput = TestDiagnosticOutput()
    
    private static func supportsOslogCapture(_ iOSVersion: String) throws -> Bool {
        guard let majorVersionComponent = iOSVersion.components(separatedBy: ".").first,
            let majorVerson = Int(majorVersionComponent) else
        {
            throw RuntimeVersionError.invalidRuntime(iOSVersion)
        }
        // iOS 9 does not have tail binary, so oslog tail is not supported
        return majorVerson > 9
    }
}
