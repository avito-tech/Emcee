import Foundation

public extension FileManager {
    func filesExist(_ files: [String]) -> Bool {
        for file in files {
            if !fileExists(atPath: file) {
                return false
            }
        }
        return true
    }
}
