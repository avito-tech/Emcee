import Extensions
import Foundation
import Models
import ResourceLocationResolver

private class ResourceLocationArg: SubprocessArgument, CustomStringConvertible {
    private let resourceLocation: ResourceLocation
    private let packageName: PackageName

    public init(resourceLocation: ResourceLocation, packageName: PackageName) {
        self.resourceLocation = resourceLocation
        self.packageName = packageName
    }
    
    public func stringValue() throws -> String {
        let result = try ResourceLocationResolver.sharedResolver.resolvePath(resourceLocation: resourceLocation)
        switch result {
        case .directlyAccessibleFile(let path):
            return path
        case .contentsOfArchive(let containerPath, let filenameInArchive):
            if let filenameInArchive = filenameInArchive {
                return containerPath.appending(pathComponent: filenameInArchive)
            } else {
                return containerPath.appending(pathComponent: try PackageName.targetFileName(packageName))
            }
        }
    }
    
    public var description: String {
        do {
            return try stringValue()
        } catch {
            return "Error resolving resource location \(resourceLocation): \(error)"
        }
    }
}

public extension ResourceLocation {
    public func asArgumentWith(packageName: PackageName) -> SubprocessArgument {
        return ResourceLocationArg(resourceLocation: self, packageName: packageName)
    }
}
