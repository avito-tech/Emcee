import Foundation

public struct AuxiliaryPaths: Hashable {
    /** Absolute path to fbxctest binary. */
    public let fbxctest: String
    
    /** Absolute path to fbsimctl binary. */
    public let fbsimctl: String
    
    /** Where the runner can store temporary stuff. */
    public let tempFolder: String

    public init(fbxctest: String, fbsimctl: String, tempFolder: String) {
        self.fbxctest = fbxctest
        self.fbsimctl = fbsimctl
        self.tempFolder = tempFolder
    }
}
