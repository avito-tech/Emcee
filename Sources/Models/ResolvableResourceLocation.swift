import Foundation

/// A result of resolving `ResourceLocation` object.
public enum ResolvingResult {
    /// A given `ResourceLocation` object is pointing to the local file on disk
    case directlyAccessibleFile(path: String)
    
    /// A given `ResourceLocation` object is pointing to archive that has been fetched and extracted.
    /// If URL had a fragment, then `filenameInArchive` will be non-nil.
    case contentsOfArchive(containerPath: String, filenameInArchive: String?)
}

public protocol ResolvableResourceLocation {
    var resourceLocation: ResourceLocation { get }
    func resolve() throws -> ResolvingResult
}

