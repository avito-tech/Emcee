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
    
    /** Where the runner can store temporary stuff. */
    public let tempFolder: String

    private init(fbxctest: String, fbsimctl: String, tempFolder: String) {
        self.fbxctest = fbxctest
        self.fbsimctl = fbsimctl
        self.tempFolder = tempFolder
    }

    /** CONSIDER using AuxiliaryPathsFactory. Creates a model with the given values without any validation. */
    public static func withoutValidatingValues(
        fbxctest: String,
        fbsimctl: String,
        tempFolder: String) -> AuxiliaryPaths
    {
        return AuxiliaryPaths(fbxctest: fbxctest, fbsimctl: fbsimctl, tempFolder: tempFolder)
    }
    
    public static let empty = AuxiliaryPaths(fbxctest: "", fbsimctl: "", tempFolder: "")
}
