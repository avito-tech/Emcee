import Foundation
import Basic

open class DeployableItem: CustomStringConvertible {
    public let name: String
    public let files: Set<DeployableFile>
    
    public init(name: String, files: Set<DeployableFile>) {
        self.name = name
        self.files = files
    }
    
    public var description: String {
        return "<\(type(of: self)): \(name), \(files.count) files>"
    }
}
