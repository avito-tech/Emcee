import CommonTestModels
import Foundation
import ResultStreamModels
import ResultStreamModelsTestHelpers
import XCTest

public final class RSTestStartedTests: XCTestCase {
    func test() throws {
        check(
            input: RSTestStartedTestInput.input(testName: TestName(className: "ClassName", methodName: "test_method")),
            equals: RSTestStarted(
                structuredPayload: RSTestEventPayload(
                    resultInfo: RSStreamedActionResultInfo(resultIndex: 1),
                    testIdentifier: RSActionTestSummaryIdentifiableObject(
                        identifier: "ClassName/test_method()",
                        name: "test_method()"
                    )
                )
            )
        )
    }
}
