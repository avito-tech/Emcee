import Foundation
import Types
import XCTest

class EitherTests: XCTestCase {
    private struct SomeError: Error, Equatable, Codable {
        let thisIsError: String
    }

    func test___success_is_left() {
        XCTAssertEqual(
            Either<String, SomeError>.left("hello"),
            Either<String, SomeError>.success("hello")
        )
    }

    func test___comparing_left() {
        XCTAssertNotEqual(
            Either<String, SomeError>.left("left"),
            Either<String, SomeError>.left("oops")
        )
    }

    func test___error_is_right() {
        XCTAssertEqual(
            Either<String, SomeError>.right(SomeError(thisIsError: "error")),
            Either<String, SomeError>.error(SomeError(thisIsError: "error"))
        )
    }

    func test___comparing_right() {
        XCTAssertNotEqual(
            Either<String, SomeError>.right(SomeError(thisIsError: "error1")),
            Either<String, SomeError>.right(SomeError(thisIsError: "error2"))
        )
    }

    func test___encoding_left() throws {
        let expected = Either<String, SomeError>.left("hello")
        let data = try JSONEncoder().encode(expected)
        let decoded = try JSONDecoder().decode(Either<String, SomeError>.self, from: data)
        XCTAssertEqual(decoded, expected)
    }

    func test___encoding_right() throws {
        let expected = Either<String, SomeError>.right(SomeError(thisIsError: "error"))
        let data = try JSONEncoder().encode(expected)
        let decoded = try JSONDecoder().decode(Either<String, SomeError>.self, from: data)
        XCTAssertEqual(decoded, expected)
    }
    
    func test___left() {
        let either = Either<String, Bool>.left("hello")
        XCTAssertEqual(either.left, "hello")
        XCTAssertNil(either.right)
    }
    
    func test___right() {
        let either = Either<String, Bool>.right(true)
        XCTAssertEqual(either.right, true)
        XCTAssertNil(either.left)
    }
    
    func test___map_result() {
        let either = Either<Int, Error>.left(0)
        
        XCTAssertEqual(
            try either.mapResult { _ in "hello" }.dematerialize(),
            "hello"
        )
    }
    
    func test___map_result___for_error() {
        let error = SomeError(thisIsError: "error")
        let either = Either<Int, Error>.error(error)
        
        XCTAssertThrowsError(
            try either.mapResult { _ in "hello" }.dematerialize()
        )
    }
}
