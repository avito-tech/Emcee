import Foundation
import Models
import ModelsTestHelpers
import XCTest

final class SimulatorControlToolTests: XCTestCase {
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    func test__decoding_fbsimctl() {
        XCTAssertEqual(
            try decoder.decode(
                [String: SimulatorControlTool].self,
                from: "{\"value\": \"\(SimulatorControlToolFixtures.fakeFbsimctlUrl)\"}".data(using: .utf8)!
            ),
            ["value": SimulatorControlToolFixtures.fakeFbsimctlTool]
        )
    }
    
    func test_encoding_fbsimctl() {
        let expectedStringValue = SimulatorControlToolFixtures.fakeFbsimctlUrl.absoluteString.replacingOccurrences(
            of: "/",
            with: "\\/"
        )
        
        XCTAssertEqual(
            try encoder.encode(["value": SimulatorControlToolFixtures.fakeFbsimctlTool]),
            "{\"value\":\"\(expectedStringValue)\"}".data(using: .utf8)
        )
    }
}

