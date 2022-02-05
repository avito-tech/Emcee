import Foundation
import TypedResourceLocation

public typealias AdditionalAppBundleLocation = TypedResourceLocation<AdditionalAppBundleResourceLocationType>

public final class AdditionalAppBundleResourceLocationType: ResourceLocationType {
    public static let name = "additional app bundle"
}
