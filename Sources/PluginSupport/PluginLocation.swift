import Foundation
import TypedResourceLocation

public typealias PluginLocation = TypedResourceLocation<PluginResourceLocationType>

public final class PluginResourceLocationType: ResourceLocationType {
    public static let name = "emcee plugin"
}
