import Foundation

public protocol RepresentableByResourceLocation {
    var resourceLocation: ResourceLocation { get }
}

public typealias FbsimctlLocation = TypedResourceLocation<FbsimctlResourceLocationType>
public typealias FbxctestLocation = TypedResourceLocation<FbxctestResourceLocationType>
public typealias PluginLocation   = TypedResourceLocation<PluginResourceLocationType>

public final class FbsimctlResourceLocationType: ResourceLocationType {
    public static let name = "fbsimctl"
}

public final class FbxctestResourceLocationType: ResourceLocationType {
    public static let name = "fbxctest"
}

public final class PluginResourceLocationType: ResourceLocationType {
    public static let name = "emcee plugin"
}
