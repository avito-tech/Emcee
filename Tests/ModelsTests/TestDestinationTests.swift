import Foundation
import Models
import XCTest

final class TestDestinationTests: XCTestCase {
    func test__converting_to_human_readable_format() throws {
        XCTAssertEqual(
            try TestDestination(deviceType: "iPhone SE", runtime: "11.3").humanReadableTestDestination,
            "iPhone SE, iOS 11.3")
    }
    
    func test__converting_human_readable_format_to_destination() {
        XCTAssertEqual(
            try TestDestination.from(humanReadableTestDestination: "iPhone SE, iOS 11.3"),
            try TestDestination(deviceType: "iPhone SE", runtime: "11.3"))
    }
    
    func test__converting_from_incorrect_format_throws() {
        XCTAssertThrowsError(try TestDestination.from(humanReadableTestDestination: ", iOS 11.3"))
        XCTAssertThrowsError(try TestDestination.from(humanReadableTestDestination: "iPhone SE, iOS"))
        XCTAssertThrowsError(try TestDestination.from(humanReadableTestDestination: ", iOS"))
        XCTAssertThrowsError(try TestDestination.from(humanReadableTestDestination: ""))
        XCTAssertThrowsError(try TestDestination.from(humanReadableTestDestination: "iPhone SE 11.3"))
    }
    
    func test__creating_from_json() throws {
        let decoder = JSONDecoder()
        let jsonData = "{\"deviceType\": \"iPhone SE\", \"runtime\": \"11.3\"}".data(using: .utf8)!
        XCTAssertEqual(
            try decoder.decode(TestDestination.self, from: jsonData),
            try TestDestination(deviceType: "iPhone SE", runtime: "11.3"))
    }
    
    func test__creating_from_json_legacy() throws {
        let decoder = JSONDecoder()
        let jsonData = "{\"deviceType\": \"iPhone SE\", \"iOSVersion\": \"11.3\"}".data(using: .utf8)!
        XCTAssertEqual(
            try decoder.decode(TestDestination.self, from: jsonData),
            try TestDestination(deviceType: "iPhone SE", runtime: "11.3"))
    }
}

