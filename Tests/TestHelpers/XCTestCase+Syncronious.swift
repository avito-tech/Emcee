import XCTest

extension XCTestCase {
    // Makes asynchronous functions syncronous. Example:
    //
    // let int = runSyncronously { completion in
    //     DispatchQueue.main.async {
    //         completion(42)
    //     }
    // }
    //
    // XCTAssertEqual(int, 42)
    //
    public func runSyncronously<T>(
        timeout: TimeInterval = 15,
        asyncFunction: @escaping (_ completion: @escaping (T) -> ()) throws -> ()
    ) throws -> T {
        var resultOrNil: T?
        
        let expectation = self.expectation(description: "Awaiting for result of type \(T.self)")
        try asyncFunction { result in
            resultOrNil = result
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: timeout)
        
        if let result = resultOrNil {
            return result
        } else {
            throw ExpectationAwaitingError()
        }
    }
}
