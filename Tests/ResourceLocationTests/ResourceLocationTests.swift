import Foundation
import ResourceLocation
import Tmp
import XCTest

final class ResourceLocationTests: XCTestCase {
    func test__decoding_JSON_with_string__maps_to_localFilePath() throws {
        let temp = NSTemporaryDirectory()
        let jsonData = Data("{\"url\": \"\(temp)\"}".utf8)
        let decoded = try JSONDecoder().decode(ResourceLocation.self, from: jsonData)
        XCTAssertEqual(decoded, ResourceLocation.localFilePath(temp))
    }
    
    func test__decoding_JSON_with_string_URL__maps_to_remoteUrl() throws {
        let urlString = "https://example.com/file.zip#path/to/file.txt"
        let jsonData = Data("{\"url\": \"\(urlString)\"}".utf8)
        let decoded = try JSONDecoder().decode(ResourceLocation.self, from: jsonData)
        XCTAssertEqual(decoded, ResourceLocation.remoteUrl(URL(string: urlString)!, [:]))
    }
    
    func test__decoding_JSON_with_single_string__maps_to_localFilePath() throws {
        let temp = NSTemporaryDirectory()
                let jsonData = Data("{\"value\": \"\(temp)\"}".utf8)
                let decoded = try JSONDecoder().decode([String: ResourceLocation].self, from: jsonData)
                XCTAssertEqual(decoded["value"], ResourceLocation.localFilePath(temp))
    }
    
    func test__decoding_JSON_with_single_string_URL__maps_to_remoteUrl() throws {
            let urlString = "https://example.com/file.zip#path/to/file.txt"
            let jsonData = Data("{\"value\": \"\(urlString)\"}".utf8)
            let decoded = try JSONDecoder().decode([String: ResourceLocation].self, from: jsonData)
            XCTAssertEqual(decoded["value"], ResourceLocation.remoteUrl(URL(string: urlString)!, nil))
    }
    
    func test__decoding_JSON_with_string_URL_with_headers__maps_to_remoteUrl() throws {
        let urlString = "https://example.com/file.zip#path/to/file.txt"
        let jsonData = Data("{\"url\": \"\(urlString)\", \"headers\": {\"key1\": \"value1\", \"key2\": \"value2\"}}".utf8)
        let decoded = try JSONDecoder().decode(ResourceLocation.self, from: jsonData)
        XCTAssertEqual(decoded, ResourceLocation.remoteUrl(URL(string: urlString)!, ["key1":"value1", "key2": "value2"]))
    }
    
    func test__encoding_localFilePath__maps_to_string() throws {
        let temp = NSTemporaryDirectory()
        let data = try JSONEncoder().encode(ResourceLocation.localFilePath(temp))
        let decoded = try JSONSerialization.jsonObject(with: data, options: [])
        guard let decodedDict = decoded as? NSDictionary else {
            return XCTFail("Unexpected decoding result: \(decoded)")
        }
        XCTAssertEqual(decodedDict["url"] as? String, temp)
    }
    
    func test__encoding_remoteUrl__maps_to_string_URL() throws {
        let urlString = "https://example.com/file.zip#path/to/file.txt"
        let data = try JSONEncoder().encode(ResourceLocation.remoteUrl(URL(string: urlString)!, [:]))
        let decoded = try JSONSerialization.jsonObject(with: data, options: [])
        guard let decodedDict = decoded as? NSDictionary else {
            return XCTFail("Unexpected decoding result: \(decoded)")
        }
        XCTAssertEqual(decodedDict["url"] as? String, urlString)
        let headers = decodedDict["headers"] as! [String: String]
        XCTAssertEqual(headers.count, 0)
    }
    
    func test__encoding_remoteUrl_with_headers_maps_to_string_URL() throws {
        let urlString = "https://example.com/file.zip#path/to/file.txt"
        let data = try JSONEncoder().encode(ResourceLocation.remoteUrl(URL(string: urlString)!, ["key":"value"]))
        let decoded = try JSONSerialization.jsonObject(with: data, options: [])
        guard let decodedDict = decoded as? NSDictionary else {
            return XCTFail("Unexpected decoding result: \(decoded)")
        }
        XCTAssertEqual(decodedDict["url"] as? String, urlString)
        let headers = decodedDict["headers"] as! [String: String]
        XCTAssertEqual(headers.count, 1)
        XCTAssertEqual(headers["key"], "value")
    }
    
    func test___string_value() {
        XCTAssertEqual(ResourceLocation.localFilePath("/path").stringValue, "/path")
        XCTAssertEqual(
            ResourceLocation.remoteUrl(URL(string: "http://example.com/file.zip")!, [:]).stringValue,
            "http://example.com/file.zip"
        )
        XCTAssertEqual(
            ResourceLocation.remoteUrl(URL(string: "http://example.com/file.zip#file")!, [:]).stringValue,
            "http://example.com/file.zip#file"
        )
    }
    
    func test___location_with_spaces_in_local_path() throws {
        let tempFolder = try TemporaryFolder(deleteOnDealloc: true)
        let path = try tempFolder.createFile(filename: "some file")
        XCTAssertNoThrow(try ResourceLocation.from(path.pathString))
    }
    
    func test___location__from_json_with_spaces_in_local_path() throws {
        let jsonData = Data("{\"url\": \"/path/to/file name.txt\"}".utf8)
        let decoded = try JSONDecoder().decode(ResourceLocation.self, from: jsonData)
        XCTAssertEqual(decoded, ResourceLocation.localFilePath("/path/to/file name.txt"))
    }
    
    func test__decoding_string_with_headers() throws {
            let value = """
            {"url": "https://example.url", "headers": {"h1": "v1"}}
            """
            let decoded = try ResourceLocation.from(value)
            XCTAssertEqual(
                decoded,
                ResourceLocation.remoteUrl(URL(string: "https://example.url")!, ["h1": "v1"])
            )
        }
}

