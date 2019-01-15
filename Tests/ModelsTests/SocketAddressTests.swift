import Foundation
import Models
import XCTest

final class SocketAddressTests: XCTestCase {
    func test___converting___to_and_from_string() throws {
        let address = SocketAddress(host: "host", port: 42)
        XCTAssertEqual(address, try SocketAddress.from(string: address.asString))
    }
    
    func test___parsing_string() throws {
        let input = "{\"address\": \"localhost:42\"}"
        let parsedAddress = try JSONDecoder().decode([String: SocketAddress].self, from: input.data(using: .utf8)!)
        XCTAssertEqual(parsedAddress["address"], SocketAddress(host: "localhost", port: 42))
    }
}

