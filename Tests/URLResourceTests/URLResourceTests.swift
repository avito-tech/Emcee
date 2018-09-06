import Basic
import FileCache
import Swifter
import URLResource
import XCTest

final class URLResourceTests: XCTestCase {
    var temporaryDirectory: TemporaryDirectory!
    var server: HttpServer?
    var serverPort = 0
    var fileCache: FileCache!
    
    override func setUp() {
        do {
            temporaryDirectory = try TemporaryDirectory(removeTreeOnDeinit: true)
            fileCache = FileCache(cachesUrl: URL(fileURLWithPath: temporaryDirectory.path.asString))
            server = HttpServer()
            try server?.start(0)
            serverPort = try server?.port() ?? 0
        } catch {
            XCTFail("Failed: \(error)")
        }
    }
    
    override func tearDown() {
        server?.stop()
    }
    
    func testWithAvailableResource() throws {
        let expectedContents = "some fetched contents"
        server?["/get"] = { _ in HttpResponse.ok(.text(expectedContents)) }
        
        
        let resource = URLResource(fileCache: fileCache, urlSession: URLSession.shared)
        let handler = BlockingHandler()
        resource.fetchResource(
            url: URL(string: "http://localhost:\(serverPort)/get/")!,
            handler: handler)
        let contentUrl = try handler.wait(until: Date().addingTimeInterval(5))
        
        XCTAssertEqual(try String(contentsOf: contentUrl), expectedContents)
    }
    
    func testWithUnavailableResource() throws {
        server?["/get"] = { _ in HttpResponse.internalServerError }
        
        let resource = URLResource(fileCache: fileCache, urlSession: URLSession.shared)
        let handler = BlockingHandler()
        resource.fetchResource(
            url: URL(string: "http://localhost:\(serverPort)/get/")!,
            handler: handler)
        XCTAssertThrowsError(try handler.wait(until: Date().addingTimeInterval(5)))
    }
}
