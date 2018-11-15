import DistRun
import Foundation
import RESTMethods
import Swifter
import XCTest

final class QueueServerRequestParserTests: XCTestCase {
    enum Result: Error {
        case throwable
    }
    
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    
    func testParseErrorMappedIntoInternalErrors() {
        let parser = QueueServerRequestParser(decoder: decoder)
        let httpResponse = parser.parse(request: HttpRequest()) { (decodedObject: Int) -> (RESTResponse) in
            throw Result.throwable
        }
        switch httpResponse {
        case .internalServerError: break
        default: XCTFail("Unexpected response: \(httpResponse)")
        }
    }
    
    func testDecodedObjectIsCorrectlyPassed() {
        let parser = QueueServerRequestParser(decoder: decoder)
        
        let httpRequest = HttpRequest()
        httpRequest.body = [UInt8]("{\"value\": 42}".data(using: .utf8)!)
        
        var actuallyDecodedObject: [String: Int]?
        
        _ = parser.parse(request: httpRequest) { (decodedObject: [String: Int]) -> (RESTResponse) in
            actuallyDecodedObject = decodedObject
            throw Result.throwable
        }
        
        XCTAssertEqual(actuallyDecodedObject, ["value": 42])
    }
    
    func testResponseIsPassedBackAsEncodedJson() {
        let parser = QueueServerRequestParser(decoder: decoder)
        
        let httpRequest = HttpRequest()
        httpRequest.body = [UInt8]("{\"value\": 42}".data(using: .utf8)!)
        
        let expectedResponse = RESTResponse.aliveReportAccepted
        
        let httpResponse = parser.parse(request: httpRequest) { (decodedObject: [String: Int]) -> (RESTResponse) in
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
                let writtenObject = try decoder.decode(RESTResponse.self, from: writable.data)
                switch writtenObject {
                case .aliveReportAccepted: break
                default: XCTFail("Incorrect object: \(writtenObject). Expected: \(expectedResponse)")
                }
            } catch {
                XCTFail("Unexpected error: \(error)")
            }
        default:
            XCTFail("Unexpected response: \(httpResponse)")
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
