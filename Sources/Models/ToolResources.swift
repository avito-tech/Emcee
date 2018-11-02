import Foundation

public final class ToolResources: Codable, Hashable {
    /// Location of fbsimctl tool.
    public let fbsimctl: ResourceLocation
    
    /// Location of fbxctest tool.
    public let fbxctest: ResourceLocation
    
    public init(fbsimctl: ResourceLocation, fbxctest: ResourceLocation) {
        self.fbsimctl = fbsimctl
        self.fbxctest = fbxctest
    }
    
    public static func == (left: ToolResources, right: ToolResources) -> Bool {
        return left.fbsimctl == right.fbsimctl && left.fbxctest == right.fbxctest
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(fbsimctl)
        hasher.combine(fbxctest)
    }
}
