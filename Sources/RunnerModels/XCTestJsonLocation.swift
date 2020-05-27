import Foundation
import TypedResourceLocation

public typealias XCTestJsonLocation = TypedResourceLocation<XCTestJsonResourceLocationType>

public final class XCTestJsonResourceLocationType: ResourceLocationType {
    public static let name = "XCTestJson.dylib"
}
