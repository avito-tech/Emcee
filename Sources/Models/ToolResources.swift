import Foundation

public final class ToolResources {
    /// Location of fbsimctl tool.
    public let fbsimctl: ResolvableResourceLocation
    
    /// Location of fbxctest tool.
    public let fbxctest: ResolvableResourceLocation
    
    public init(fbsimctl: ResolvableResourceLocation, fbxctest: ResolvableResourceLocation) {
        self.fbsimctl = fbsimctl
        self.fbxctest = fbxctest
    }
}
