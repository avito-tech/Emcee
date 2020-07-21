import Foundation
import SimulatorPoolModels
import SimulatorPoolTestHelpers
import XCTest

final class SimulatorControlToolTests: XCTestCase {
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let simulatorControlTool = SimulatorControlTool(
        location: .insideUserLibrary,
        tool: .simctl
    )

    override func setUp() {
        encoder.outputFormatting = [.sortedKeys]
    }
    
    func test__decoding_fbsimctl() {
        XCTAssertEqual(
            try decoder.decode(
                [String: SimulatorControlTool].self,
                from: """
                {
                    "value": {
                        "tool": {
                            "toolType": "fbsimctl",
                            "location": "\(SimulatorControlToolFixtures.fakeFbsimctlUrl.absoluteString)"
                        },
                        "location": "insideEmceeTempFolder"
                    }
                }
                """.data(using: .utf8)!
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
            String(data: try encoder.encode(["value": SimulatorControlToolFixtures.fakeFbsimctlTool]), encoding: .utf8),
            "{\"value\":{\"location\":\"insideEmceeTempFolder\",\"tool\":{\"location\":\"\(expectedStringValue)\",\"toolType\":\"fbsimctl\"}}}"
        )
    }

    func test__decoding_simctl() {
        XCTAssertEqual(
            try decoder.decode(
                [String: SimulatorControlTool].self,
                from: """
                {
                    "value": {
                        "location": "insideUserLibrary",
                        "tool": {
                            "toolType": "simctl"
                        }
                    }
                }
                """.data(using: .utf8)!
            ),
            ["value": simulatorControlTool]
        )
    }

    func test_encoding_simctl() {
        XCTAssertEqual(
            String(data: try encoder.encode(["value": simulatorControlTool]), encoding: .utf8),
            "{\"value\":{\"location\":\"insideUserLibrary\",\"tool\":{\"toolType\":\"simctl\"}}}"
        )
    }
}

