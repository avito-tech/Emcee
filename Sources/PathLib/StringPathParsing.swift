import Foundation

final class StringPathParsing {
    static func components(path: String) -> [String] {
        return path.components(separatedBy: "/").filter { !$0.isEmpty }
    }
}
