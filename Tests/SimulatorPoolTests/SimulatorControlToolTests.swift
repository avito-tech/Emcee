import Foundation
import Models
import ModelsTestHelpers
import SimulatorPoolModels
import SimulatorPoolTestHelpers
import XCTest

final class SimulatorControlToolTests: XCTestCase {
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    override func setUp() {
        encoder.outputFormatting = [.sortedKeys]
    }
    
    func test__decoding_fbsimctl() {
        XCTAssertEqual(
            try decoder.decode(
                [String: SimulatorControlTool].self,
                from: "{\"value\": {\"toolType\": \"fbsimctl\", \"location\": \"\(SimulatorControlToolFixtures.fakeFbsimctlUrl)\"}}".data(using: .utf8)!
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
            "{\"value\":{\"location\":\"\(expectedStringValue)\",\"toolType\":\"fbsimctl\"}}".data(using: .utf8)
        )
    }

    func test__decoding_simctl() {
        XCTAssertEqual(
            try decoder.decode(
                [String: SimulatorControlTool].self,
                from: "{\"value\": {\"toolType\": \"simctl\"}}".data(using: .utf8)!
            ),
            ["value": SimulatorControlTool.simctl]
        )
    }

    func test_encoding_simctl() {
        XCTAssertEqual(
            try encoder.encode(["value": SimulatorControlTool.simctl]),
            "{\"value\":{\"toolType\":\"simctl\"}}".data(using: .utf8)
        )
    }
}

