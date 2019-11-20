import Foundation
import RESTMethods
import RESTServer
import Swifter
import XCTest

final class RequestParserTests: XCTestCase {
    enum Result: Error, CustomStringConvertible {
        case error
        
        var description: String {
            switch self {
            case .error:
                return "(error with description)"
            }
        }
    }
    
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    
    private typealias TypeThatMatchesDefaultRequest = [String: Int]
    private typealias TypeThatDontMatchDefaultRequest = [String: String]
    private var defaultRequestForThisTest: HttpRequest {
        let request = HttpRequest()
        request.path = "request_path"
        request.body = [UInt8]("{\"value\": 42}".data(using: .utf8)!)
        return request
    }
    
    func test___parse___produces_bad_request_response___if_request_is_malformed() {
        let parser = RequestParser(decoder: decoder)
        
        let httpResponse = parser.parse(request: defaultRequestForThisTest) { (decodedObject: TypeThatDontMatchDefaultRequest) -> (Int) in
            1
        }
        
        assert(
            httpResponse: httpResponse,
            isBadRequestResponseWithText:
            """
            Failed to process request with path "request_path", error: "typeMismatch(Swift.String, Swift.DecodingError.Context(codingPath: [_JSONKey(stringValue: "value", intValue: nil)], debugDescription: "Expected to decode String but found a number instead.", underlyingError: nil))"
            """
        )
    }
    
    func test___parse___produces_bad_request_response___if_responseProducer_throws() {
        let parser = RequestParser(decoder: decoder)
        
        let httpResponse = parser.parse(request: defaultRequestForThisTest) { (decodedObject: TypeThatMatchesDefaultRequest) -> (Int) in
            throw Result.error
        }
        
        assert(
            httpResponse: httpResponse,
            isBadRequestResponseWithText:
            """
            Failed to process request with path "request_path", error: "(error with description)"
            """
        )
    }
    
    func test___parse___passes_parsed_object_to_responseProducer___if_request_is_correct() {
        let parser = RequestParser(decoder: decoder)
        
        var actuallyDecodedObject: [String: Int]?
        
        _ = parser.parse(request: defaultRequestForThisTest) { (decodedObject: TypeThatMatchesDefaultRequest) -> (Int) in
            actuallyDecodedObject = decodedObject
            throw Result.error
        }
        
        XCTAssertEqual(actuallyDecodedObject, ["value": 42])
    }
    
    func test___parse___returns_correct_httpResponse_with_object_returned_from_responseProducer___if_request_is_correct() {
        let parser = RequestParser(decoder: decoder)
        
        let expectedResponse = ReportAliveResponse.aliveReportAccepted
        
        let httpResponse = parser.parse(request: defaultRequestForThisTest) { (decodedObject: TypeThatMatchesDefaultRequest) -> (ReportAliveResponse) in
            return expectedResponse
        }
        
        switch httpResponse {
        case .raw(let httpCode, let httpStatus, let headers, let writer):
            XCTAssertEqual(httpCode, 200)
            XCTAssertEqual(httpStatus, "OK")
            XCTAssertEqual(headers?["Content-Type"], "application/json")
            
            let writable = HttpResponseWritable()
            XCTAssertNoThrow(try writer?(writable))
            do {
                let writtenObject = try decoder.decode(ReportAliveResponse.self, from: writable.data)
                XCTAssertEqual(writtenObject, expectedResponse)
            } catch {
                XCTFail("Unexpected error: \(error)")
            }
        default:
            XCTFail("Unexpected response: \(httpResponse)")
        }
    }
    
    private func assert(
        httpResponse: HttpResponse,
        isBadRequestResponseWithText expectedText: String,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        switch httpResponse {
        case .badRequest(let body):
            switch body {
            case .text(let actualText)?:
                XCTAssertEqual(actualText, expectedText, file: file, line: line)
            default:
                XCTFail("Unexpected body: \(String(describing: body))", file: file, line: line)
            }
        default:
            XCTFail("Unexpected response: \(httpResponse)", file: file, line: line)
        }
    }
}

private class HttpResponseWritable: HttpResponseBodyWriter {
    struct NotImplemented: Error {}
    var data = Data()
    
    public init() {
        
    }
    
    func write(_ file: String.File) throws {
        throw NotImplemented()
    }
    func write(_ data: [UInt8]) throws {
        throw NotImplemented()
    }
    func write(_ data: ArraySlice<UInt8>) throws {
        throw NotImplemented()
    }
    func write(_ data: NSData) throws {
        throw NotImplemented()
    }
    func write(_ data: Data) throws {
        self.data.append(data)
    }
}
