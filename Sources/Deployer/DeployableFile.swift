import Foundation

public struct DeployableFile: CustomStringConvertible, Hashable {
    /** Local location of the file */
    public let source: String
    /** Target location of the file inside Deployable's container */
    public let destination: String

    public init(source: String, destination: String) {
        self.source = source
        self.destination = destination
    }
    
    public var description: String {
        return "<\(type(of: self)) \(source) -> \(destination)>"
    }
}
