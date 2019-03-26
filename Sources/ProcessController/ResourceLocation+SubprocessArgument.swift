import Extensions
import Foundation
import Models
import ResourceLocationResolver

private class ResolvableResourceLocationArg: SubprocessArgument, CustomStringConvertible {
    private let resolvableResourceLocation: ResolvableResourceLocation
    private let packageName: PackageName?
    
    enum ArgError: Error, CustomStringConvertible {
        case cannotResolve(ResolvableResourceLocation, containerPath: String)
        
        var description: String {
            switch self {
            case .cannotResolve(let resolvableResourceLocation, let containerPath):
                return "Unable to generate direct local path for resource location '\(resolvableResourceLocation)': "
                + "the location is not accessible directly, and it has been fetched into container path '\(containerPath)'. "
                + "But it is not possible to determine a file inside container as no file name was provided in the resource location. "
                + "You can provide a filename inside archive via URL fragment, e.g. http://example.com/archive.zip#filename"
            }
        }
    }

    public init(
        resolvableResourceLocation: ResolvableResourceLocation,
        packageName: PackageName?)
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
            } else if let packageName = packageName {
                return containerPath.appending(pathComponent: try PackageName.targetFileName(packageName))
            } else {
                throw ArgError.cannotResolve(resolvableResourceLocation, containerPath: containerPath)
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
    func asArgumentWith(packageName: PackageName) -> SubprocessArgument {
        return ResolvableResourceLocationArg(resolvableResourceLocation: self, packageName: packageName)
    }
    
    func asArgument() -> SubprocessArgument {
        return ResolvableResourceLocationArg(resolvableResourceLocation: self, packageName: nil)
    }
}
