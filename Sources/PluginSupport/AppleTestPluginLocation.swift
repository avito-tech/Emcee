import Foundation
import TypedResourceLocation

public typealias AppleTestPluginLocation = TypedResourceLocation<AppleTestPluginResourceLocationType>

public final class AppleTestPluginResourceLocationType: ResourceLocationType {
    public static let name = "emcee plugin"
}
