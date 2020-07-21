import Foundation
import SimulatorPoolModels
import XCTest

final class TestDestinationTests: XCTestCase {
    func test__creating_from_json() throws {
        let decoder = JSONDecoder()
        let jsonData = "{\"deviceType\": \"iPhone SE\", \"runtime\": \"11.3\"}".data(using: .utf8)!
        XCTAssertEqual(
            try decoder.decode(TestDestination.self, from: jsonData),
            try TestDestination(deviceType: "iPhone SE", runtime: "11.3")
        )
    }
}
