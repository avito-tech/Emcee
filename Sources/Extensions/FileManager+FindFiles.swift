import Foundation

public extension FileManager {
    func walkUpTheHierarchy(path: String, untilFileIsFound filename: String) -> String? {
        guard path.hasPrefix("/") else { return nil }
        var p = path
        while p != "/" {
            if fileExists(atPath: p.appending(pathComponent: filename)) {
                return p
            }
            p = p.deletingLastPathComponent
        }
        return nil
    }
}
