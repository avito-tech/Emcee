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

    func test__decoding_simctl() {
        XCTAssertEqual(
            try decoder.decode(
                [String: SimulatorControlTool].self,
                from: Data(
                    """
                        {
                            "value": {
                                "location": "insideUserLibrary",
                                "tool": {
                                    "toolType": "simctl"
                                }
                            }
                        }
                    """.utf8
                )
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

