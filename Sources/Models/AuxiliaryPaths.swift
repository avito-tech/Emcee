import Foundation

/**
 * AuxiliaryPaths represents auxillary tools that are used by the runner. It is recommended to create this model
 * using AuxiliaryPathsFactory which will validate the arguments and supports URLs.
 */
public struct AuxiliaryPaths: Hashable {
    /** Absolute path to fbxctest binary. */
    public let fbxctest: String
    
    /** Absolute path to fbsimctl binary. */
    public let fbsimctl: String
    
    /** Locations (path or ZIP file URL) of .emceeplugin bundles. */
    public let plugins: [ResourceLocation]
    
    private init(fbxctest: String, fbsimctl: String, plugins: [ResourceLocation]) {
        self.fbxctest = fbxctest
        self.fbsimctl = fbsimctl
        self.plugins = plugins
    }

    /** CONSIDER using AuxiliaryPathsFactory. Creates a model with the given values without any validation. */
    public static func withoutValidatingValues(
        fbxctest: String,
        fbsimctl: String,
        plugins: [ResourceLocation]) -> AuxiliaryPaths
    {
        return AuxiliaryPaths(fbxctest: fbxctest, fbsimctl: fbsimctl, plugins: plugins)
    }
    
    public var hashValue: Int {
        return fbxctest.hashValue ^ fbsimctl.hashValue ^ plugins.count
    }
    
    public static let empty = AuxiliaryPaths(fbxctest: "", fbsimctl: "", plugins: [])
}
