import FileCache
import Swifter
import TemporaryStuff
import URLResource
import XCTest

final class URLResourceTests: XCTestCase {
    let tempFolder = try! TemporaryFolder(deleteOnDealloc: true)
    var server = HttpServer()
    var serverPort = 0
    lazy var fileCache = FileCache(cachesUrl: URL(fileURLWithPath: tempFolder.absolutePath.pathString))
    
    private func setServerHandler(handler: @escaping () -> (HttpResponse)) throws {
        try server.start(0)
        serverPort = try server.port()
        server["/get"] = { _ in handler() }
    }
    
    override func tearDown() {
        server.stop()
    }
    
    func testWithAvailableResource() throws {
        let expectedContents = "some fetched contents"
        try setServerHandler { HttpResponse.ok(.text(expectedContents)) }
        
        let resource = URLResource(fileCache: fileCache, urlSession: URLSession.shared)
        let handler = BlockingURLResourceHandler()
        resource.fetchResource(
            url: URL(string: "http://localhost:\(serverPort)/get/")!,
            handler: handler)
        let contentUrl = try handler.wait(limit: 5)
        
        XCTAssertEqual(try String(contentsOf: contentUrl), expectedContents)
    }
    
    func testWithUnavailableResource() throws {
        try setServerHandler { HttpResponse.internalServerError }
        
        let resource = URLResource(fileCache: fileCache, urlSession: URLSession.shared)
        let handler = BlockingURLResourceHandler()
        resource.fetchResource(
            url: URL(string: "http://localhost:\(serverPort)/get/")!,
            handler: handler)
        XCTAssertThrowsError(try handler.wait(limit: 5))
    }
}
