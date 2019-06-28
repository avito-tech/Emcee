import Foundation

open class DeployableItem: CustomStringConvertible, Hashable {
    public let name: String
    public let files: Set<DeployableFile>
    
    public init(name: String, files: Set<DeployableFile>) {
        self.name = name
        self.files = files
    }
    
    public var description: String {
        return "<\(type(of: self)): \(name), \(files.count) files>"
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(files)
    }
    
    public static func == (left: DeployableItem, right: DeployableItem) -> Bool {
        return left.name == right.name && left.files == right.files
    }
}
