import Foundation

public extension ProcessInfo {
    var executablePath: String {
        return arguments.elementAtIndex(0, "Path to executable")
    }
    
    var executableUrl: URL {
        return URL(fileURLWithPath: executablePath)
    }
}
