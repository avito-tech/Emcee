import Foundation

/// Represents locatios of the tools that are used by the runner.
public struct AuxiliaryResources: Hashable {
    /** Location of fbxctest tool. */
    public let fbxctest: ResourceLocation
    
    /** Location of fbsimctl tool. */
    public let fbsimctl: ResourceLocation
    
    /** Locations of .emceeplugin bundles. */
    public let plugins: [ResourceLocation]
    
    public init(fbxctest: ResourceLocation, fbsimctl: ResourceLocation, plugins: [ResourceLocation]) {
        self.fbxctest = fbxctest
        self.fbsimctl = fbsimctl
        self.plugins = plugins
    }
    
    public var hashValue: Int {
        return fbxctest.hashValue ^ fbsimctl.hashValue ^ plugins.count
    }
    
    public static let empty = AuxiliaryResources(fbxctest: .void, fbsimctl: .void, plugins: [])
}
