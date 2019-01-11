import Foundation

public extension ProcessInfo {
    public var executablePath: String {
        return arguments.elementAtIndex(0, "Path to executable")
    }
    
    public var executableUrl: URL {
        return URL(fileURLWithPath: executablePath)
    }
}
