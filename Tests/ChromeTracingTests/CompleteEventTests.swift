import ChromeTracing
import TestHelpers
import XCTest

final class CompleteEventTests: XCTestCase {
    func test() throws {
        let event = CompleteEvent(
            category: "cat",
            name: "name",
            timestamp: .seconds(5),
            duration: .seconds(10),
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
                "name": "name",
                "cname": "bad",
                "ph": "X",
                "pid": "pid",
                "tid": "tid",
                "ts": 5000000,
                "dur": 10000000,
                "args": [
                    "arg": "value",
                ]
            ] as NSDictionary
        }
    }
}
