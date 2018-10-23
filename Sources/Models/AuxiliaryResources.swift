import Foundation

/// Represents locatios of the tools that are used by the runner.

// TODO: remove hashable?
public struct AuxiliaryResources: Hashable {
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
    
    public static func == (left: AuxiliaryResources, right: AuxiliaryResources) -> Bool {
        return left.fbsimctl.resourceLocation == right.fbsimctl.resourceLocation
            && left.fbxctest.resourceLocation == right.fbxctest.resourceLocation
            && left.plugins.map { $0.resourceLocation } == right.plugins.map { $0.resourceLocation }
    }
    
    public var hashValue: Int {
        return fbxctest.resourceLocation.hashValue ^ fbsimctl.resourceLocation.hashValue ^ plugins.count
    }
    

}
