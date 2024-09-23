import CommonTestModels
import Foundation
import XCTest

final class TestNameTests: XCTestCase {
    let value = ["value": TestName(className: "ClassName", methodName: "testMethod")]
    let encoder = JSONEncoder()

    override func setUp() {
        encoder.outputFormatting = .sortedKeys
    }
    
    func test___decoding_from_string() throws {
        let result: [String: TestName] = try fromJson(
            string: "{\"value\":\"ClassName\\/testMethod\"}"
        )

        XCTAssertEqual(value, result)
    }

    func test___decoding_from_string_with_fields() throws {
        let result = try encoder.encode(value)
        
        let expectedValue = try fromJson(
            string: """
            {
                "value": {
                    "className": "ClassName",
                    "methodName": "testMethod"
                }
            }
            """
        )

        XCTAssertEqual(
            String(data: result, encoding: .utf8)!,
            String(data: try encoder.encode(expectedValue), encoding: .utf8)!
        )
    }
    
    func test___encoding_to_string() throws {
        let result = try encoder.encode(value)
        
        let expectedValue = """
        {
            "value": {
                "className": "ClassName",
                "methodName": "testMethod"
            }
        }
        """.components(separatedBy: .whitespacesAndNewlines).joined()
        
        XCTAssertEqual(
            result,
            Data(expectedValue.utf8)
        )
    }
    
    private func fromJson(string: String) throws -> [String : TestName] {
        return try JSONDecoder().decode(
            [String: TestName].self,
            from: Data(string.utf8)
        )
    }
}
