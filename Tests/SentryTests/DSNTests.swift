import Foundation
import Sentry
import XCTest

final class DSNTests: XCTestCase {
    func test___creating_dsn_from_string() throws {
        let string = "http://public:secret@example.com/projid"
        XCTAssertEqual(
            try DSN.create(dsnString: string),
            DSN(
                storeUrl: URL(string: "http://example.com/api/projid/store/")!,
                publicKey: "public",
                secretKey: "secret",
                projectId: "projid"
            )
        )
    }
    
    func test___creating_dsn_from_invalid_string___throws() throws {
        XCTAssertThrowsError(try DSN.create(dsnString: "abc"))
    }
    
    func test___creating_dsn_from_without_public_and_secret___throws() throws {
        XCTAssertThrowsError(try DSN.create(dsnString: "http://example.com/projid"))
    }
    
    func test___creating_dsn_from_without_secret___throws() throws {
        XCTAssertThrowsError(try DSN.create(dsnString: "http://public@example.com/projid"))
    }
    
    func test___creating_dsn_from_without_project_id___throws() throws {
        XCTAssertThrowsError(try DSN.create(dsnString: "http://public:secret@example.com/"))
    }
}
