import Foundation

public final class ToolResources: Codable, Hashable, CustomStringConvertible {
    /// Location of fbsimctl tool.
    public let fbsimctl: FbsimctlLocation
    
    /// Location of fbxctest tool.
    public let fbxctest: FbxctestLocation
    
    public init(fbsimctl: FbsimctlLocation, fbxctest: FbxctestLocation) {
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
    
    public var description: String {
        return "<\((type(of: self))) fbsimctl: \(fbsimctl), fbxctest: \(fbxctest)>"
    }
}
