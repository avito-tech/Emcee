import Foundation

/// Represents locatios of the tools that are used by the runner.
public struct AuxiliaryPaths: Hashable {
    /** Location of fbxctest tool. */
    public let fbxctest: ResourceLocation
    
    /** Location of fbsimctl tool. */
    public let fbsimctl: ResourceLocation
    
    /** Locations (path or ZIP file URL) of .emceeplugin bundles. */
    public let plugins: [ResourceLocation]
    
    public init(fbxctest: ResourceLocation, fbsimctl: ResourceLocation, plugins: [ResourceLocation]) {
        self.fbxctest = fbxctest
        self.fbsimctl = fbsimctl
        self.plugins = plugins
    }
    
    public var hashValue: Int {
        return fbxctest.hashValue ^ fbsimctl.hashValue ^ plugins.count
    }
    
    public static let empty = AuxiliaryPaths(fbxctest: .void, fbsimctl: .void, plugins: [])
}
