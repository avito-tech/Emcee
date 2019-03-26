import Foundation
import Models
import TempFolder
import XCTest

final class ResourceLocationTests: XCTestCase {
    func test__decoding_JSON_with_string__maps_to_localFilePath() throws {
        let temp = NSTemporaryDirectory()
        let jsonData = "{\"value\": \"\(temp)\"}".data(using: .utf8)!
        let decoded = try JSONDecoder().decode([String: ResourceLocation].self, from: jsonData)
        XCTAssertEqual(decoded["value"], ResourceLocation.localFilePath(temp))
    }
    
    func test__decoding_JSON_with_string_URL__maps_to_remoteUrl() throws {
        let urlString = "https://example.com/file.zip#path/to/file.txt"
        let jsonData = "{\"value\": \"\(urlString)\"}".data(using: .utf8)!
        let decoded = try JSONDecoder().decode([String: ResourceLocation].self, from: jsonData)
        XCTAssertEqual(decoded["value"], ResourceLocation.remoteUrl(URL(string: urlString)!))
    }
    
    func test__encoding_localFilePath__maps_to_string() throws {
        let temp = NSTemporaryDirectory()
        let data = try JSONEncoder().encode(["value": ResourceLocation.localFilePath(temp)])
        let decoded = try JSONSerialization.jsonObject(with: data, options: [])
        guard let decodedDict = decoded as? NSDictionary else {
            return XCTFail("Unexpected decoding result: \(decoded)")
        }
        XCTAssertEqual(decodedDict["value"] as? String, temp)
    }
    
    func test__encoding_remoteUrl__maps_to_string_URL() throws {
        let urlString = "https://example.com/file.zip#path/to/file.txt"
        let data = try JSONEncoder().encode(["value": ResourceLocation.remoteUrl(URL(string: urlString)!)])
        let decoded = try JSONSerialization.jsonObject(with: data, options: [])
        guard let decodedDict = decoded as? NSDictionary else {
            return XCTFail("Unexpected decoding result: \(decoded)")
        }
        XCTAssertEqual(decodedDict["value"] as? String, urlString)
    }
    
    func test___string_value() {
        XCTAssertEqual(ResourceLocation.localFilePath("/path").stringValue, "/path")
        XCTAssertEqual(
            ResourceLocation.remoteUrl(URL(string: "http://example.com/file.zip")!).stringValue,
            "http://example.com/file.zip"
        )
        XCTAssertEqual(
            ResourceLocation.remoteUrl(URL(string: "http://example.com/file.zip#file")!).stringValue,
            "http://example.com/file.zip#file"
        )
    }
    
    func test___location_with_spaces_in_local_path() throws {
        let tempFolder = try TempFolder(cleanUpAutomatically: true)
        let path = try tempFolder.createFile(filename: "some file")
        XCTAssertNoThrow(try ResourceLocation.from(path.pathString))
    }
    
    func test___location__from_json_with_spaces_in_local_path() throws {
        let jsonData = "{\"value\": \"/path/to/file name.txt\"}".data(using: .utf8)!
        let decoded = try JSONDecoder().decode([String: ResourceLocation].self, from: jsonData)
        XCTAssertEqual(decoded["value"], ResourceLocation.localFilePath("/path/to/file name.txt"))
    }
}

