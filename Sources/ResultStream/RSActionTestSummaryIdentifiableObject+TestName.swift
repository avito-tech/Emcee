import Foundation
import RunnerModels
import ResultStreamModels

extension RSActionTestSummaryIdentifiableObject {
    func testName() throws -> TestName {
        let components = identifier
            .stringValue
            .replacingOccurrences(of: "()", with: "")
            .split(separator: "/")
        guard components.count == 2 else {
            struct TestNameError: Error, CustomStringConvertible {
                let string: String
                var description: String {
                    "Can't parse test name from '\(string)'. Expected a string that looks like 'ClassName/test()'"
                }
            }
            throw TestNameError(string: identifier.stringValue)
        }
        return TestName(
            className: String(components[0]),
            methodName: String(components[1])
        )
    }
}
