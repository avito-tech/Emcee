import Foundation
import TypedResourceLocation

public typealias TestBundleLocation = TypedResourceLocation<TestBundleResourceLocationType>

public final class TestBundleResourceLocationType: ResourceLocationType {
    public static let name = "xctest bundle"
}
