import Foundation
import TestDestination

public final class TestDestinationFixture {
    static func fixture(
        _ stringValues: [String: String] = ["TestDestinationFixture": "Value"],
        _ intValues: [String: Int] = [:]
    ) -> TestDestination {
        var result = TestDestination()
        stringValues.forEach { (key: String, value: String) in
            result = result.add(key: key, value: value)
        }
        return result
    }
}
