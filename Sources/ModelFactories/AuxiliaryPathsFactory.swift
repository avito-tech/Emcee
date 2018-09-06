import Foundation
import Models

public final class AuxiliaryPathsFactory {
    private let fileManager = FileManager()
    public init() {}
    
    public func createWith(
        fbxctest: ResourceLocation,
        fbsimctl: ResourceLocation,
        tempFolder: String = "")
        throws -> AuxiliaryPaths
    {
        if !tempFolder.isEmpty {
            try fileManager.createDirectory(atPath: tempFolder, withIntermediateDirectories: true, attributes: [:])
        }
        
        let resolver = ResourceLocationResolver.sharedResolver
        let fbxctestPath = try resolver.resolvePath(resourceLocation: fbxctest).with(archivedFile: "fbxctest")
        let fbsimctlPath = try resolver.resolvePath(resourceLocation: fbsimctl).with(archivedFile: "fbsimctl")
        
        return AuxiliaryPaths.withoutValidatingValues(
            fbxctest: fbxctestPath,
            fbsimctl: fbsimctlPath,
            tempFolder: tempFolder)
    }
}
