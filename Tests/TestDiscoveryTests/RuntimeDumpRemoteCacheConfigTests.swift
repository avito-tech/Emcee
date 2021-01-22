import Foundation
import PathLib
import RequestSender
import SocketModels
import TestDiscovery
import TestHelpers
import XCTest

final class RuntimeDumpRemoteCacheConfigTests: XCTestCase {
    func test___decoding_full_json() throws {
        let json = Data(
            """
            {
                "credentials": {
                    "username": "username",
                    "password": "password"
                },
                "storeHttpMethod": "put",
                "obtainHttpMethod": "get",
                "relativePathToRemoteStorage": "remote_cache_path/",
                "socketAddress": "example.com:1337"
            }
            """.utf8
        )

        let config = assertDoesNotThrow {
            try JSONDecoder().decode(RuntimeDumpRemoteCacheConfig.self, from: json)
        }

        XCTAssertEqual(
            config,
            RuntimeDumpRemoteCacheConfig(
                credentials: Credentials(username: "username", password: "password"),
                storeHttpMethod: .put,
                obtainHttpMethod: .get,
                relativePathToRemoteStorage: RelativePath("remote_cache_path/"),
                socketAddress: SocketAddress(host: "example.com", port: 1337)
            )
        )
    }
}

