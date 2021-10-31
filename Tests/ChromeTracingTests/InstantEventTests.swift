import ChromeTracing
import TestHelpers
import XCTest

final class InstantEventTests: XCTestCase {
    func test() throws {
        let event = InstantEvent(
            category: "cat",
            name: "name",
            timestamp: .seconds(5),
            scope: .process,
            processId: "pid",
            threadId: "tid",
            args: ["arg" : EventArgumentValue(payload: "value")],
            color: ColorName.bad
        )
        
        let data = try JSONEncoder().encode(event)
        assert {
            try JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary
        } equals: {
            [
                "cat": "cat",
                "cname": "bad",
                "name": "name",
                "ph": "i",
                "pid": "pid",
                "tid": "tid",
                "ts": 5000000,
                "s": "p",
                "args": [
                    "arg": "value",
                ]
            ] as NSDictionary
        }
    }
}
