import FileCache
import Swifter
import TemporaryStuff
import URLResource
import XCTest

final class URLResourceTests: XCTestCase {
    let tempFolder = try! TemporaryFolder(deleteOnDealloc: true)
    var server = HttpServer()
    var serverPort = 0
    lazy var url = URL(string: "http://localhost:\(serverPort)/get/")!
    lazy var fileCache = try! FileCache(cachesUrl: URL(fileURLWithPath: tempFolder.absolutePath.pathString))
    lazy var resource = URLResource(fileCache: fileCache, urlSession: URLSession.shared)
    
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
        
        let handler = BlockingURLResourceHandler()
        resource.fetchResource(
            url: url,
            handler: handler
        )
        let contentUrl = try handler.wait(limit: 5)
        
        XCTAssertEqual(try String(contentsOf: contentUrl), expectedContents)
    }
    
    func testWithUnavailableResource() throws {
        try setServerHandler { HttpResponse.internalServerError }
        
        let handler = BlockingURLResourceHandler()
        resource.fetchResource(
            url: url,
            handler: handler
        )
        XCTAssertThrowsError(try handler.wait(limit: 5))
    }
    
    func test___does_not_throw_error___when_content_length_matches_downloaded_size() throws {
        let expectedContents = "some fetched contents"
        try setServerHandler {
            HttpResponse.raw(200, "OK", ["Content-Length": "\(expectedContents.count)"], { writer in
                try writer.write(expectedContents.data(using: .utf8)!)
            })
        }
        
        let handler = BlockingURLResourceHandler()
        resource.fetchResource(
            url: url,
            handler: handler
        )
        
        _ = try handler.wait(limit: 5)
    }
    
    func test___throws_error___when_content_length_mismatches_downloaded_size() throws {
        let expectedContents = "some fetched contents"
        try setServerHandler {
            HttpResponse.raw(200, "OK", ["Content-Length": "\(expectedContents.count * 3)"], { writer in
                try writer.write(expectedContents.data(using: .utf8)!)
            })
        }
        
        let handler = BlockingURLResourceHandler()
        resource.fetchResource(
            url: url,
            handler: handler
        )
        XCTAssertThrowsError(
            try handler.wait(limit: 5),
            "Incorrect content length should be detected"
        )
    }
    
    func test___deleting_resource() throws {
        let expectedContents = "some fetched contents"
        try setServerHandler { HttpResponse.ok(.text(expectedContents)) }
        
        let handler = BlockingURLResourceHandler()
        resource.fetchResource(
            url: url,
            handler: handler
        )
        let contentUrl = try handler.wait(limit: 5)
        
        XCTAssertTrue(FileManager.default.fileExists(atPath: contentUrl.path))
        try resource.deleteResource(url: url)
        XCTAssertFalse(FileManager.default.fileExists(atPath: contentUrl.path))
    }
}
