import Foundation

public protocol RepresentableByResourceLocation {
    var resourceLocation: ResourceLocation { get }
}

public typealias AdditionalAppBundleLocation = TypedResourceLocation<AdditionalAppBundleResourceLocationType>
public typealias AppBundleLocation = TypedResourceLocation<AppBundleResourceLocationType>
public typealias FbsimctlLocation = TypedResourceLocation<FbsimctlResourceLocationType>
public typealias FbxctestLocation = TypedResourceLocation<FbxctestResourceLocationType>
public typealias PluginLocation = TypedResourceLocation<PluginResourceLocationType>
public typealias RunnerAppLocation = TypedResourceLocation<RunnerAppResourceLocationType>
public typealias TestBundleLocation = TypedResourceLocation<TestBundleResourceLocationType>
public typealias QueueServerRunConfigurationLocation = TypedResourceLocation<QueueServerRunConfigurationLocationType>
public typealias AnalyticsConfigurationLocation = TypedResourceLocation<AnalyticsConfigurationLocationType>


public final class AdditionalAppBundleResourceLocationType: ResourceLocationType {
    public static let name = "additional app bundle"
}

public final class AppBundleResourceLocationType: ResourceLocationType {
    public static let name = "app bundle"
}

public final class FbsimctlResourceLocationType: ResourceLocationType {
    public static let name = "fbsimctl"
}

public final class FbxctestResourceLocationType: ResourceLocationType {
    public static let name = "fbxctest"
}

public final class PluginResourceLocationType: ResourceLocationType {
    public static let name = "emcee plugin"
}

public final class RunnerAppResourceLocationType: ResourceLocationType {
    public static let name = "xct runner app"
}

public final class TestBundleResourceLocationType: ResourceLocationType {
    public static let name = "xctest bundle"
}

public final class QueueServerRunConfigurationLocationType: ResourceLocationType {
    public static let name = "queue server run configuration"
}

public final class AnalyticsConfigurationLocationType: ResourceLocationType {
    public static let name = "analytics configuration"
}
