import Foundation
import PathLib
import ProcessController
import ResourceLocation

private class ResolvableResourceLocationArg: SubprocessArgument, CustomStringConvertible {
    private let resolvableResourceLocation: ResolvableResourceLocation
    private let implicitFilenameInArchive: String?
    
    enum ArgError: Error, CustomStringConvertible {
        case cannotResolve(ResolvableResourceLocation, containerPath: AbsolutePath)
        
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
        implicitFilenameInArchive: String?
    ) {
        self.resolvableResourceLocation = resolvableResourceLocation
        self.implicitFilenameInArchive = implicitFilenameInArchive
    }
    
    public func stringValue() throws -> String {
        let result = try resolvableResourceLocation.resolve()
        switch result {
        case .directlyAccessibleFile(let path):
            return try path.stringValue()
        case .contentsOfArchive(let containerPath, let filenameInArchive):
            if let filenameInArchive = filenameInArchive {
                return try containerPath.appending(component: filenameInArchive).stringValue()
            } else if let implicitFilenameInArchive = implicitFilenameInArchive {
                return try containerPath.appending(component: implicitFilenameInArchive).stringValue()
            } else {
                throw ArgError.cannotResolve(resolvableResourceLocation, containerPath: containerPath)
            }
        }
    }
    
    public var description: String {
        switch resolvableResourceLocation.resourceLocation {
        case .localFilePath(let path):
            return path
        case .remoteUrl(let url, _):
            var items = ["url: \(url)"]
            if let implicitFilenameInArchive = implicitFilenameInArchive {
                items.append("file: \(implicitFilenameInArchive)")
            }
            return "<\(type(of: self)): " + items.joined(separator: " ") + ">"
        }
    }
}

public extension ResolvableResourceLocation {
    func asArgumentWith(implicitFilenameInArchive: String) -> SubprocessArgument {
        return ResolvableResourceLocationArg(resolvableResourceLocation: self, implicitFilenameInArchive: implicitFilenameInArchive)
    }
    
    func asArgument() -> SubprocessArgument {
        return ResolvableResourceLocationArg(resolvableResourceLocation: self, implicitFilenameInArchive: nil)
    }
}
