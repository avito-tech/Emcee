@testable import RuntimeDump
import BuildArtifacts
import Models
import PathLib
import RequestSender
import RequestSenderTestHelpers
import ResourceLocation
import XCTest

class RuntimeDumpRemoteCacheTests: XCTestCase {
    private let requestSender = FakeRequestSender(result: nil, requestSenderError: nil)
    private var cache: RuntimeDumpRemoteCache!

    override func setUp() {
        cache = DefaultRuntimeDumpRemoteCache(
            config: config(),
            sender: requestSender
        )
    }

    func test__store() throws {
        let xcTestBundleLocation = TestBundleLocation(ResourceLocation.localFilePath("xcTestBundleLocation"))
        let expectedPath = "/pathToRemoteStorage/a74c1c98661e4c27fc3e569f40c74feaf4775d1b77c4a82928364728ab6c23b0.json"
        let queryResult = RuntimeQueryResultFixtures.queryResult()

        try cache.store(
            tests: queryResult.testsInRuntimeDump,
            xcTestBundleLocation: xcTestBundleLocation
        )

        XCTAssertEqual(requestSender.credentials, Credentials(username: "username", password: "password"))
        guard let request = requestSender.request as? RentimeDumpRemoteCacheStoreRequest else {
            XCTFail("Wrong request type: \(String(describing: requestSender.request))")
            return
        }

        XCTAssertEqual(request.httpMethod, HTTPMethod.post)
        XCTAssertEqual(request.pathWithLeadingSlash, expectedPath)
        XCTAssertEqual(request.payload, queryResult.testsInRuntimeDump)
    }

    func test__results__success_request() {
        let xcTestBundleLocation = TestBundleLocation(ResourceLocation.localFilePath("xcTestBundleLocation"))
        let expectedPath = "/pathToRemoteStorage/a74c1c98661e4c27fc3e569f40c74feaf4775d1b77c4a82928364728ab6c23b0.json"
        let senderResult = RuntimeQueryResultFixtures.queryResult().testsInRuntimeDump
        requestSender.result = senderResult
        
        let result = try? cache.results(xcTestBundleLocation: xcTestBundleLocation)

        XCTAssertEqual(requestSender.credentials, Credentials(username: "username", password: "password"))
        guard let request = requestSender.request as? RuntimeDumpRemoteCacheResultRequest else {
            XCTFail("Wrong request type: \(String(describing: requestSender.request))")
            return
        }

        XCTAssertEqual(request.httpMethod, HTTPMethod.get)
        XCTAssertEqual(request.pathWithLeadingSlash, expectedPath)
        XCTAssertNil(request.payload)
        XCTAssertEqual(result, senderResult)
    }

    func test__results__error_request() {
        let xcTestBundleLocation = TestBundleLocation(ResourceLocation.localFilePath("xcTestBundleLocation"))
        let expectedPath = "/pathToRemoteStorage/a74c1c98661e4c27fc3e569f40c74feaf4775d1b77c4a82928364728ab6c23b0.json"
        requestSender.requestSenderError = RequestSenderError.noData
        let expectation = self.expectation(description: "Result throws")

        do {
            _ = try cache.results(xcTestBundleLocation: xcTestBundleLocation)
        } catch {
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 3)
        XCTAssertEqual(requestSender.credentials, Credentials(username: "username", password: "password"))
        guard let request = requestSender.request as? RuntimeDumpRemoteCacheResultRequest else {
            XCTFail("Wrong request type: \(String(describing: requestSender.request))")
            return
        }

        XCTAssertEqual(request.httpMethod, HTTPMethod.get)
        XCTAssertEqual(request.pathWithLeadingSlash, expectedPath)
        XCTAssertNil(request.payload)
    }

    private func config() -> RuntimeDumpRemoteCacheConfig {
        return RuntimeDumpRemoteCacheConfig(
            credentials: Credentials(username: "username", password: "password"),
            storeHttpMethod: .post,
            obtainHttpMethod: .get,
            relativePathToRemoteStorage: RelativePath("pathToRemoteStorage"),
            socketAddress: SocketAddress(host: "example.com", port: 1337)
        )
    }
}
