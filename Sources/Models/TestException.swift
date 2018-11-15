import Foundation

public struct TestException: Codable, CustomStringConvertible, Equatable {
    public let reason: String
    public let filePathInProject: String
    public let lineNumber: Int32
    
    public init(reason: String, filePathInProject: String, lineNumber: Int32) {
        self.reason = reason
        self.filePathInProject = filePathInProject
        self.lineNumber = lineNumber
    }
    
    public var description: String {
        return "<\(type(of: self)) \(reason) at: \(filePathInProject):\(lineNumber)>"
    }
}
