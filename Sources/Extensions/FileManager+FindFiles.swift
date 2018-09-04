import Foundation

public extension FileManager {
    /**
     Returns a list of files that have a given prefix, suffix and extension.
     
     For example, if folder `/a/` contains the following files:
     
     ```
     /a/libMyLibrary.a
     /a/libHerLibrary.a
     /a/libHisLibrary.a
     /a/libTheirLibrary.a
     /a/libxml.a
     /a/README.md
     ```
     
     the call with the `path: "/a", suffix: "lib", prefix: "Library", pathExtension: "a"` arguments will return
     the following list:
     
     ```
     /a/libMyLibrary.a
     /a/libHerLibrary.a
     /a/libHisLibrary.a
     ```
     
     - Parameters:
         - path: folder which contents should be iterated
         - prefix: filename prefix
         - suffix: filename suffix
         - pathExtension: an extension of the file being iterated
     
     - Returns: All files which filename has the given prefix and suffix with the provided extension.
     
     - Throws: FileManager errors in case of read errors.
     */
    func findFiles(path: String, prefix: String = "", suffix: String = "", pathExtension: String = "") throws -> [String] {
        return try
            contentsOfDirectory(atPath: path)
                .filter {
                    $0.pathExtension == pathExtension
                        && $0.deletingPathExtension.hasPrefix(prefix)
                        && $0.deletingPathExtension.hasSuffix(suffix)
                }
                .map { path.appending(pathComponent: $0) }
    }
    
    func findFiles(path: String, prefix: String = "", suffix: String = "", pathExtension: String = "", defaultValue: [String]) -> [String] {
        do {
            return try findFiles(path: path, prefix: prefix, suffix: suffix, pathExtension: pathExtension)
        } catch {
            return defaultValue
        }
    }
    
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
