//import DateProviderTestHelpers
//import EmceeExtensions
//import FileCache
//import FileSystem
//import Tmp
//import TestHelpers
//import URLResource
//import XCTest
//
//final class URLResourceTests: XCTestCase {
//    lazy var dateProvider = DateProviderFixture()
//    lazy var tempFolder = assertDoesNotThrow { try TemporaryFolder() }
////    lazy var server = HttpServer()
//    lazy var serverPort = 0
//    lazy var url = URL(string: "http://localhost:\(serverPort)/get/")!
//    lazy var fileCache = assertDoesNotThrow {
//        try FileCache(
//            cachesContainer: tempFolder.absolutePath,
//            dateProvider: dateProvider,
//            fileSystem: LocalFileSystemProvider().create()
//        )
//    }
//    lazy var resource = URLResourceImpl(
//        fileCache: fileCache,
//        logger: .noOp,
//        urlSession: URLSession.shared
//    )
//    
//    private func setServerHandler(handler: @escaping () -> (HttpResponse)) throws {
//        try server.start(0)
//        serverPort = try server.port()
//        server["/get"] = { _ in handler() }
//    }
//    
//    override func tearDown() {
//        server.stop()
//    }
//    
//    func testWithAvailableResource() throws {
//        let expectedContents = "some fetched contents"
//        try setServerHandler { HttpResponse.ok(.text(expectedContents)) }
//        
//        let handler = BlockingURLResourceHandler()
//        resource.fetchResource(
//            url: url,
//            handler: handler,
//            headers: [:]
//        )
//        let contentPath = try handler.wait(limit: 5, remoteUrl: url)
//        
//        XCTAssertEqual(try String(contentsOf: contentPath.fileUrl), expectedContents)
//    }
//    
//    func testWithUnavailableResource() throws {
//        try setServerHandler { HttpResponse.internalServerError }
//        
//        let handler = BlockingURLResourceHandler()
//        resource.fetchResource(
//            url: url,
//            handler: handler,
//            headers: [:]
//        )
//        XCTAssertThrowsError(try handler.wait(limit: 5, remoteUrl: url))
//    }
//    
//    func test___does_not_throw_error___when_content_length_matches_downloaded_size() throws {
//        let expectedContents = "some fetched contents"
//        try setServerHandler {
//            HttpResponse.raw(200, "OK", ["Content-Length": "\(expectedContents.count)"], { writer in
//                try writer.write(Data(expectedContents.utf8))
//            })
//        }
//        
//        let handler = BlockingURLResourceHandler()
//        resource.fetchResource(
//            url: url,
//            handler: handler,
//            headers: [:]
//        )
//        
//        _ = try handler.wait(limit: 5, remoteUrl: url)
//    }
//    
//    func test___throws_error___when_content_length_mismatches_downloaded_size() throws {
//        let expectedContents = "some fetched contents"
//        try setServerHandler {
//            HttpResponse.raw(200, "OK", ["Content-Length": "\(expectedContents.count * 3)"], { writer in
//                try writer.write(Data(expectedContents.utf8))
//            })
//        }
//        
//        let handler = BlockingURLResourceHandler()
//        resource.fetchResource(
//            url: url,
//            handler: handler,
//            headers: [:]
//        )
//        XCTAssertThrowsError(
//            try handler.wait(limit: 5, remoteUrl: url),
//            "Incorrect content length should be detected"
//        )
//    }
//    
//    func test___deleting_resource() throws {
//        let expectedContents = "some fetched contents"
//        try setServerHandler { HttpResponse.ok(.text(expectedContents)) }
//        
//        let handler = BlockingURLResourceHandler()
//        resource.fetchResource(
//            url: url,
//            handler: handler,
//            headers: [:]
//        )
//        let contentPath = try handler.wait(limit: 5, remoteUrl: url)
//        
//        XCTAssertTrue(FileManager.default.fileExists(atPath: contentPath.pathString))
//        try resource.deleteResource(url: url)
//        XCTAssertFalse(FileManager.default.fileExists(atPath: contentPath.pathString))
//    }
//}
