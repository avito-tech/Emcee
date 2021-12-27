import DateProvider
import FileCache
import FileSystem
import Foundation
import EmceeLogging
import EmceeExtensions
import PathLib
import ProcessController
import ResourceLocation
import ResourceLocationResolver
import Swifter
import SynchronousWaiter
import Tmp
import TestHelpers
import URLResource
import URLSessionTestHelpers
import XCTest
import FileSystemTestHelpers

final class ResourceLocationResolverTests: XCTestCase {
    
    func test___resolving_local_file() throws {
        let expectedPath = try tempFolder.createFile(filename: "some_local_file")
        
        let result = try resolver.resolvePath(resourceLocation: .localFilePath(expectedPath.pathString))
        
        switch result {
        case .directlyAccessibleFile(let actualPath):
            XCTAssertEqual(expectedPath, actualPath)
        case .contentsOfArchive:
            XCTFail("Unexpected result")
        }
    }
    
    func test___resolving_local_file_with_space_in_path() throws {
        let expectedPath = try tempFolder.createFile(filename: "some local file")
        
        let result = try resolver.resolvePath(resourceLocation: ResourceLocation.from(expectedPath.pathString))
        
        switch result {
        case .directlyAccessibleFile(let actualPath):
            XCTAssertEqual(expectedPath, actualPath)
        case .contentsOfArchive:
            XCTFail("Unexpected result")
        }
    }
    
    func test___resolving_local_file___resolves_relative_to_working_directory___when_local_file_path_is_relative() throws {
        let relativeLocalFile = "relative_local_file"
        let result = try resolver.resolvePath(resourceLocation: .localFilePath(relativeLocalFile))
        
        switch result {
        case .directlyAccessibleFile(let actualPath):
            XCTAssertEqual(workingDirectory.appending(relativeLocalFile), actualPath)
        case .contentsOfArchive:
            XCTFail("Unexpected result")
        }
    }

    func test___fetching_resource_with_fragment___resolves_into_archive_contents_with_filename_in_archive() throws {
        let server = try startServer(serverPath: "/contents/example.zip", localPath: smallZipFile)
        let remoteUrl = URL(string: "http://localhost:\(server.port)/contents/example.zip#example")!
        
        let result = try resolver.resolvePath(resourceLocation: .remoteUrl(remoteUrl, [:]))
        
        switch result {
        case .directlyAccessibleFile:
            XCTFail("Unexpected result")
        case .contentsOfArchive(let containerPath, let filenameInArchive):
            XCTAssertEqual(filenameInArchive, "example")
            XCTAssertTrue(
                compareFiles(
                    path1: smallFile,
                    path2: containerPath.appending(filenameInArchive ?? "")
                )
            )
        }
        
        XCTAssertTrue(fileCache.contains(itemForURL: URL(string: "http://localhost:\(server.port)/contents/example.zip")!))
    }
    
    func test___fetching_resource_without_fragment___resolves_into_archive_contents_without_filename_in_archive() throws {
        let server = try startServer(serverPath: "/contents/example.zip", localPath: smallZipFile)
        let remoteUrl = URL(string: "http://localhost:\(server.port)/contents/example.zip")!
        
        let result = try resolver.resolvePath(resourceLocation: .remoteUrl(remoteUrl, [:]))
        
        switch result {
        case .directlyAccessibleFile:
            XCTFail("Unexpected result")
        case .contentsOfArchive(let containerPath, let filenameInArchive):
            XCTAssertEqual(filenameInArchive, nil)
            XCTAssertTrue(
                compareFiles(
                    path1: smallFile,
                    path2: containerPath.appending("example")
                )
            )
        }
        
        XCTAssertTrue(fileCache.contains(itemForURL: remoteUrl))
    }
    
    func test___once_resource_has_been_fetched___zip_file_is_truncated_to_zero_bytes_but_kept_on_disk() throws {
        let server = try startServer(serverPath: "/contents/example.zip", localPath: smallZipFile)
        let remoteUrl = URL(string: "http://localhost:\(server.port)/contents/example.zip")!
        
        _ = try resolver.resolvePath(resourceLocation: .remoteUrl(remoteUrl, [:]))
        let localCachePath = try fileCache.pathForCachedContents(ofUrl: remoteUrl)
        
        let attributes = try FileManager.default.attributesOfItem(atPath: localCachePath.pathString)
        guard let size = attributes[.size] as? NSNumber else {
            return XCTFail("Size of file is not available, but file is expected to be present on disk")
        }
        XCTAssertEqual(size.intValue, 0, "Zip file should have been erased to 0 bytes size")
    }
    
    func test___fetching_resource_from_multiple_threads() throws {
        let server = try startServer(serverPath: "/contents/example.zip", localPath: largeZipFile)
        let remoteUrl = URL(string: "http://localhost:\(server.port)/contents/example.zip")!
        let resolver = self.resolver
        
        for _ in 0 ..< maximumConcurrentOperations {
            operationQueue.addOperation {
                do {
                    let result = try resolver.resolvePath(resourceLocation: .remoteUrl(remoteUrl, [:]))
                    switch result {
                    case .directlyAccessibleFile:
                        XCTFail("Unexpected result")
                    case .contentsOfArchive(let containerPath, _):
                        XCTAssertTrue(
                            self.compareFiles(
                                path1: self.largeFile,
                                path2: containerPath.appending("example")
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
        let server = try startServer(serverPath: "/contents/example.zip", localPath: largeZipFile)
        let remoteUrl = URL(string: "http://localhost:\(server.port)/contents/example.zip")!
        let resolver = self.resolver
        
        for _ in 0 ..< maximumConcurrentOperations {
            operationQueue.addOperation {
                _ = try? resolver.resolvePath(resourceLocation: .remoteUrl(remoteUrl, [:]))
            }
        }
        operationQueue.waitUntilAllOperationsAreFinished()
        XCTAssertEqual(fakeSession.providedDownloadTasks.count, 1)
    }
    
    func test___when_zip_file_is_corrupted___it_is_removed_from_cache() throws {
        urlSession = fakeSession
        let server = try startServer(serverPath: "/contents/example.zip", localPath: corruptedZipFile)
        let remoteUrl = URL(string: "http://localhost:\(server.port)/contents/example.zip")!
        
        XCTAssertThrowsError(
            _ = try resolver.resolvePath(resourceLocation: .remoteUrl(remoteUrl, [:])),
            "Corrupted ZIP file should throw error"
        )
        
        XCTAssertFalse(fileCache.contains(itemForURL: remoteUrl))
    }
    
    func test___fetching_unavailable_resource_sequentially___attempts_to_fetch_sequentially() throws {
        var attemptsToFetchResource = 0
        
        let serverAndPort = startServer()
        serverAndPort.server["/url"] = { _ in
            attemptsToFetchResource += 1
            return .notFound
        }
        
        let remoteUrl = URL(string: "http://localhost:\(serverAndPort.port)/url")!
        
        assertThrows {
            try resolver.resolvePath(resourceLocation: .remoteUrl(remoteUrl, [:]))
        }
        
        assertThrows {
            try resolver.resolvePath(resourceLocation: .remoteUrl(remoteUrl, [:]))
        }
        
        XCTAssertEqual(
            attemptsToFetchResource,
            2,
            "2 attempts to fetch not available resource should be performed"
        )
    }
    
    var urlSession = URLSession.shared
    let fakeSession = FakeURLSession()
    let dateProvider = SystemDateProvider()
    let rootPath = AbsolutePath("/some/root/path/")
    let workingDirectory = AbsolutePath("/some/working/directory")
    lazy var resolver = ResourceLocationResolverImpl(
        fileSystem: fileSystem,
        logger: .noOp,
        urlResource: urlResource,
        processControllerProvider: DefaultProcessControllerProvider(
            dateProvider: dateProvider,
            filePropertiesProvider: FilePropertiesProviderImpl()
        ),
        commonlyUsedPathsProvider: FakeCommonlyUsedPathsProvider(
            applicationsProvider: { _ in self.rootPath.appending("Applications") },
            cachesProvider: { _ in self.rootPath.appending("Library", "Caches") },
            libraryProvider: { _ in self.rootPath.appending("Library") },
            currentWorkingDirectoryProvider: { self.workingDirectory }
        )
    )
    lazy var fileSystem = LocalFileSystemProvider().create()
    lazy var serverFolder = assertDoesNotThrow {
        try tempFolder.createDirectory(components: ["server"])
    }
    lazy var tempFolder = assertDoesNotThrow {
        try TemporaryFolder()
    }
    lazy var fileCache = assertDoesNotThrow {
        try FileCache(
            cachesContainer: tempFolder.absolutePath,
            dateProvider: dateProvider,
            fileSystem: fileSystem
        )
    }
    lazy var urlResource = URLResourceImpl(
        fileCache: fileCache,
        logger: .noOp,
        urlSession: urlSession
    )
    lazy var smallFile = assertDoesNotThrow { try createFile(name: "example", size: 4096) }
    lazy var smallZipFile = self.zipFile(toPath: serverFolder.appending("example.zip"), fromPath: smallFile)
    lazy var largeFile = assertDoesNotThrow { try createFile(name: "example", size: 12000000) }
    lazy var largeZipFile = self.zipFile(toPath: serverFolder.appending("example.zip"), fromPath: largeFile)
    lazy var corruptedZipFile = assertDoesNotThrow { try createFile(name: "corrupted", size: 1234) }
    let operationQueue = OperationQueue()
    let maximumConcurrentOperations = 10
    
    override func setUp() {
        super.setUp()
        operationQueue.maxConcurrentOperationCount = maximumConcurrentOperations
    }
    
    private func zipFile(toPath: AbsolutePath, fromPath: AbsolutePath) -> AbsolutePath {
        let process = Foundation.Process()
        process.launchPath = "/usr/bin/zip"
        process.currentDirectoryPath = fromPath.removingLastComponent.pathString
        process.arguments = ["-j", toPath.pathString, fromPath.pathString]
        process.launch()
        process.waitUntilExit()
        return toPath
    }
    
    private func compareFiles(path1: AbsolutePath, path2: AbsolutePath) -> Bool {
        let process = Foundation.Process.launchedProcess(
            launchPath: "/usr/bin/cmp",
            arguments: [path1.pathString, path2.pathString]
        )
        process.waitUntilExit()
        return process.terminationStatus == 0
    }
    
    private func createFile(name: String, size: Int) throws -> AbsolutePath {
        let keyData = Data(repeating: 0, count: size)
        let path = tempFolder.pathWith(components: [name])
        try keyData.write(to: path.fileUrl, options: .atomicWrite)
        return path
    }
    
    private func startServer() -> (server: HttpServer, port: Int) {
        let server = HttpServer()
        let port: Int = assertDoesNotThrow {
            try server.start(0, forceIPv4: false, priority: .default)
            return try server.port()
        }
        return (server: server, port: port)
    }
    
    private func startServer(serverPath: String, localPath: AbsolutePath) throws -> (server: HttpServer, port: Int) {
        let serverAndPort = startServer()
        serverAndPort.server[serverPath] = shareFile(localPath.pathString)
        return serverAndPort
    }
}
