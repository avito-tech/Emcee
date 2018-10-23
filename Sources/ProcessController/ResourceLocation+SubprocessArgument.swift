import Extensions
import Foundation
import Models
import ResourceLocationResolver

private class ResolvableResourceLocationArg: SubprocessArgument, CustomStringConvertible {
    private let resolvableResourceLocation: ResolvableResourceLocation
    private let packageName: PackageName

    public init(
        resolvableResourceLocation: ResolvableResourceLocation,
        packageName: PackageName)
    {
        self.resolvableResourceLocation = resolvableResourceLocation
        self.packageName = packageName
    }
    
    public func stringValue() throws -> String {
        let result = try resolvableResourceLocation.resolve()
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
            return "Error resolving resource location \(resolvableResourceLocation): \(error)"
        }
    }
}

public extension ResolvableResourceLocation {
    public func asArgumentWith(packageName: PackageName) -> SubprocessArgument {
        return ResolvableResourceLocationArg(resolvableResourceLocation: self, packageName: packageName)
    }
}
