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
    
    /** Where the runner can store temporary stuff. */
    public let tempFolder: String

    private init(fbxctest: String, fbsimctl: String, plugins: [ResourceLocation], tempFolder: String) {
        self.fbxctest = fbxctest
        self.fbsimctl = fbsimctl
        self.plugins = plugins
        self.tempFolder = tempFolder
    }

    /** CONSIDER using AuxiliaryPathsFactory. Creates a model with the given values without any validation. */
    public static func withoutValidatingValues(
        fbxctest: String,
        fbsimctl: String,
        plugins: [ResourceLocation],
        tempFolder: String) -> AuxiliaryPaths
    {
        return AuxiliaryPaths(fbxctest: fbxctest, fbsimctl: fbsimctl, plugins: plugins, tempFolder: tempFolder)
    }
    
    public var hashValue: Int {
        return fbxctest.hashValue ^ fbsimctl.hashValue ^ plugins.count ^ tempFolder.hashValue
    }
    
    public static let empty = AuxiliaryPaths(fbxctest: "", fbsimctl: "", plugins: [], tempFolder: "")
}
