import EmceeExtensions
import Foundation
import TestDestination
import TestHelpers
import XCTest

final class TestDestinationTests: XCTestCase {
    lazy var testDestination = TestDestination()
        .add(key: "key1", value: "string")
        .add(key: "key2", value: 42)
    lazy var encoder = JSONEncoder.pretty()
    lazy var decoder = JSONDecoder()
    
    func test___encoding() throws {
        let data = try encoder.encode(testDestination)
        let string = assertNotNil {
            String(data: data, encoding: .utf8)
        }
        
        assert {
            string
        } equals: {
            """
            {
              "key1" : "string",
              "key2" : 42
            }
            """
        }
    }
    
    func test___decoding() throws {
        let data = Data("""
        {
          "key1" : "string",
          "key2" : 42
        }
        """.utf8)
        
        let result = try decoder.decode(TestDestination.self, from: data)
        
        assert {
            result
        } equals: {
            testDestination
        }
    }
}
