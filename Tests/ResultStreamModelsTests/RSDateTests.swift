import Foundation
import ResultStreamModels
import TestHelpers
import XCTest

final class RSDateTests: XCTestCase {
    func test() throws {
        let input = """
        {
            "_type": {
                "_name": "Date"
            },
            "_value": "2020-12-22T18:51:50.000+0300"
        }
        """
        
        let data = assertNotNil { input.data(using: .utf8) }
        
        let dateComponents = DateComponents(
            calendar: Calendar(identifier: .gregorian),
            timeZone: TimeZone(secondsFromGMT: 3600 * 3),
            year: 2020,
            month: 12,
            day: 22,
            hour: 18,
            minute: 51,
            second: 50
        )
        
        let decodedValue = try JSONDecoder().decode(RSDate.self, from: data)
        let computedValue = RSDate(assertNotNil { dateComponents.date })
        
        assert {
            decodedValue
        } equals: {
            computedValue
        }
        
        assert {
            decodedValue._value
        } equals: {
            computedValue._value
        }
    }
}

