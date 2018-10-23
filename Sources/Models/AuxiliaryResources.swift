import Foundation

/// Represents locatios of the tools that are used by the runner.
public struct AuxiliaryResources {
    /** Location of fbxctest tool. */
    public let fbxctest: ResolvableResourceLocation
    
    /** Location of fbsimctl tool. */
    public let fbsimctl: ResolvableResourceLocation
    
    /** Locations of .emceeplugin bundles. */
    public let plugins: [ResolvableResourceLocation]
    
    public init(
        fbxctest: ResolvableResourceLocation,
        fbsimctl: ResolvableResourceLocation,
        plugins: [ResolvableResourceLocation])
    {
        self.fbxctest = fbxctest
        self.fbsimctl = fbsimctl
        self.plugins = plugins
    }
}
