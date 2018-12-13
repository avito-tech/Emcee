import Basic
import FileCache
import Foundation
import Models
import ResourceLocationResolver
import Swifter
import TempFolder
import URLResource
import SynchronousWaiter
import XCTest

final class ResourceLocationResolverTests: XCTestCase {
    
    func test___resolving_local_file() throws {
        let expectedPath = try tempFolder.createFile(filename: "some_local_file")
        
        let result = try resolver.resolvePath(resourceLocation: .localFilePath(expectedPath.asString))
        
        switch result {
        case .directlyAccessibleFile(let actualPath):
            XCTAssertEqual(expectedPath.asString, actualPath)
        case .contentsOfArchive:
            XCTFail("Unexpected result")
        }
    }

    func test___fetching_resource_with_fragment___resolves_into_archive_contents_with_filename_in_archive() throws {
        let server = try startServer(serverPath: "/contents/example.zip", localPath: smallZipFile.asString)
        let remoteUrl = URL(string: "http://localhost:\(server.port)/contents/example.zip#example")!
        
        let result = try resolver.resolvePath(resourceLocation: .remoteUrl(remoteUrl))
        
        switch result {
        case .directlyAccessibleFile:
            XCTFail("Unexpected result")
        case .contentsOfArchive(let containerPath, let filenameInArchive):
            XCTAssertEqual(filenameInArchive, "example")
            XCTAssertTrue(
                compareFiles(
                    path1: smallFile,
                    path2: try AbsolutePath(validating: containerPath.appending(pathComponent: filenameInArchive ?? ""))
                )
            )
        }
    }
    
    func test___fetching_resource_without_fragment___resolves_into_archive_contents_without_filename_in_archive() throws {
        let server = try startServer(serverPath: "/contents/example.zip", localPath: smallZipFile.asString)
        let remoteUrl = URL(string: "http://localhost:\(server.port)/contents/example.zip")!
        
        let result = try resolver.resolvePath(resourceLocation: .remoteUrl(remoteUrl))
        
        switch result {
        case .directlyAccessibleFile:
            XCTFail("Unexpected result")
        case .contentsOfArchive(let containerPath, let filenameInArchive):
            XCTAssertEqual(filenameInArchive, nil)
            XCTAssertTrue(
                compareFiles(
                    path1: smallFile,
                    path2: try AbsolutePath(validating: containerPath.appending(pathComponent: "example"))
                )
            )
        }
    }
    
    func test___fetching_resource_from_multiple_threads() throws {
        let server = try startServer(serverPath: "/contents/example.zip", localPath: largeZipFile.asString)
        let remoteUrl = URL(string: "http://localhost:\(server.port)/contents/example.zip")!
        let resolver = self.resolver
        
        for _ in 0 ..< maximumConcurrentOperations {
            operationQueue.addOperation {
                do {
                    let result = try resolver.resolvePath(resourceLocation: .remoteUrl(remoteUrl))
                    switch result {
                    case .directlyAccessibleFile:
                        XCTFail("Unexpected result")
                    case .contentsOfArchive(let containerPath, _):
                        XCTAssertTrue(
                            self.compareFiles(
                                path1: self.largeFile,
                                path2: try AbsolutePath(validating: containerPath.appending(pathComponent: "example"))
                            )
                        )
                    }
                } catch {
                    XCTFail("Unexpected error \(error)")
                }
            }
        }
        operationQueue.waitUntilAllOperationsAreFinished()
    }
    
    func test___fetching_resource_from_multiple_threads_starts_only_single_download_task() throws {
        urlSession = fakeSession
        let server = try startServer(serverPath: "/contents/example.zip", localPath: largeZipFile.asString)
        let remoteUrl = URL(string: "http://localhost:\(server.port)/contents/example.zip")!
        let resolver = self.resolver
        
        for _ in 0 ..< maximumConcurrentOperations {
            operationQueue.addOperation {
                _ = try? resolver.resolvePath(resourceLocation: .remoteUrl(remoteUrl))
            }
        }
        operationQueue.waitUntilAllOperationsAreFinished()
        XCTAssertEqual(fakeSession.providedDownloadTasks.count, 1)
    }
    
    var urlSession = URLSession.shared
    let fakeSession = FakeURLSession()
    lazy var resolver = ResourceLocationResolver(urlResource: urlResource)
    lazy var serverFolder = try! tempFolder.pathByCreatingDirectories(components: ["server"])
    let tempFolder = try! TempFolder()
    lazy var fileCache = FileCache(cachesUrl: URL(fileURLWithPath: tempFolder.pathWith(components: []).asString))
    lazy var urlResource = URLResource(fileCache: fileCache, urlSession: urlSession)
    lazy var smallFile = try! createFile(name: "example", size: 4096)
    lazy var smallZipFile = self.zipFile(toPath: serverFolder.appending(component: "example.zip"), fromPath: smallFile)
    lazy var largeFile = try! createFile(name: "example", size: 12000000)
    lazy var largeZipFile = self.zipFile(toPath: serverFolder.appending(component: "example.zip"), fromPath: largeFile)
    let operationQueue = OperationQueue()
    let maximumConcurrentOperations = 10
    
    override func setUp() {
        super.setUp()
        operationQueue.maxConcurrentOperationCount = maximumConcurrentOperations
    }
    
    private func zipFile(toPath: AbsolutePath, fromPath: AbsolutePath) -> AbsolutePath {
        let process = Foundation.Process()
        process.launchPath = "/usr/bin/zip"
        process.currentDirectoryPath = fromPath.parentDirectory.asString
        process.arguments = ["-j", toPath.asString, fromPath.asString]
        process.launch()
        process.waitUntilExit()
        return toPath
    }
    
    private func compareFiles(path1: AbsolutePath, path2: AbsolutePath) -> Bool {
        let process = Foundation.Process.launchedProcess(
            launchPath: "/usr/bin/cmp",
            arguments: [path1.asString, path2.asString]
        )
        process.waitUntilExit()
        return process.terminationStatus == 0
    }
    
    private func createFile(name: String, size: Int) throws -> AbsolutePath {
        var keyData = Data(count: size)
        _ = keyData.withUnsafeMutableBytes { (mutableBytes: UnsafeMutablePointer<UInt8>) -> Int32 in
            SecRandomCopyBytes(kSecRandomDefault, size, mutableBytes)
        }
        let path = tempFolder.pathWith(components: [name])
        try keyData.write(to: URL(fileURLWithPath: path.asString), options: .atomicWrite)
        return path
    }
    
    private func startServer(serverPath: String, localPath: String) throws -> (server: HttpServer, port: Int) {
        let server = HttpServer()
        server[serverPath] = shareFile(localPath)
        XCTAssertNoThrow(try server.start(0, forceIPv4: false, priority: .default))
        return (server: server, port: try server.port())
    }
}

