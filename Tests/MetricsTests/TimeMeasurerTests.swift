import DateProviderTestHelpers
import Foundation
import Metrics
import TestHelpers
import XCTest

final class TimeMeasurerTests: XCTestCase {
    lazy var dateProvider = DateProviderFixture()
    lazy var measurer = TimeMeasurerImpl(dateProvider: dateProvider)
    
    func test() throws {
        dateProvider.result = Date(timeIntervalSinceReferenceDate: 1000)
        
        let value: Int = measurer.measure(
            work: {
                dateProvider.result += 1000
                return 42
            },
            result: { error, duration in
                XCTAssertEqual(duration, 1000)
            }
        )
        XCTAssertEqual(value, 42)
    }
    
    func test___rethrows_inner_error() {
        dateProvider.result = Date(timeIntervalSinceReferenceDate: 1000)
        
        assertThrows {
            try measurer.measure(
                work: {
                    dateProvider.result += 1000
                    throw ErrorForTestingPurposes(text: "text")
                },
                result: { error, duration in
                    guard let error = error as? ErrorForTestingPurposes else {
                        failTest("Unexpected error")
                    }
                    XCTAssertEqual(error.text, "text")
                }
            ) as Int
        }
    }
}

