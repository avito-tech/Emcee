import Foundation
import Models

public final class AuxiliaryPathsFactory {
    private let fileManager = FileManager()
    public init() {}
    
    public func createWith(
        fbxctest: ResourceLocation,
        fbsimctl: ResourceLocation,
        tempFolder: String)
        throws -> AuxiliaryPaths
    {
        try fileManager.createDirectory(atPath: tempFolder, withIntermediateDirectories: true, attributes: [:])
        
        let resolver = ResourceLocationResolver.sharedResolver
        let fbxctestPath = try resolver.resolvePathToBinary(resourceLocation: fbxctest, binaryName: "fbxctest")
        let fbsimctlPath = try resolver.resolvePathToBinary(resourceLocation: fbsimctl, binaryName: "fbsimctl")
        
        return AuxiliaryPaths.withoutValidatingValues(
            fbxctest: fbxctestPath,
            fbsimctl: fbsimctlPath,
            tempFolder: tempFolder)
    }
}
