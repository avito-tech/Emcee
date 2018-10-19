import Foundation
import Models

public final class AuxiliaryPathsFactory {
    private let fileManager = FileManager()
    public init() {}
    
    public func createWith(
        fbxctest: ResourceLocation,
        fbsimctl: ResourceLocation,
        plugins: [ResourceLocation])
        throws -> AuxiliaryPaths
    {
        let resolver = ResourceLocationResolver.sharedResolver
        let fbxctestPath = try resolver.resolvePath(resourceLocation: fbxctest).with(archivedFile: "fbxctest")
        let fbsimctlPath = try resolver.resolvePath(resourceLocation: fbsimctl).with(archivedFile: "fbsimctl")
        
        return AuxiliaryPaths.withoutValidatingValues(
            fbxctest: fbxctestPath,
            fbsimctl: fbsimctlPath,
            plugins: plugins)
    }
}
