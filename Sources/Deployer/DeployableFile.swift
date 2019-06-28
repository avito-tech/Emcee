import Foundation
import PathLib

public struct DeployableFile: CustomStringConvertible, Hashable {
    /** Local location of the file */
    public let source: AbsolutePath
    /** Target location of the file inside Deployable's container */
    public let destination: RelativePath

    public init(source: AbsolutePath, destination: RelativePath) {
        self.source = source
        self.destination = destination
    }
    
    public var description: String {
        return "<\(type(of: self)) \(source) -> \(destination)>"
    }
}
