import Foundation
import TypedResourceLocation

public typealias AppBundleLocation = TypedResourceLocation<AppBundleResourceLocationType>

public final class AppBundleResourceLocationType: ResourceLocationType {
    public static let name = "app bundle"
}
