import Foundation
import TypedResourceLocation

public typealias ApkLocation = TypedResourceLocation<ApkResourceLocationType>

public final class ApkResourceLocationType: ResourceLocationType {
    public static let name = "apk"
}
