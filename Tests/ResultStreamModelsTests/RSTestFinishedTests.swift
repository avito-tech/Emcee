import Foundation
import ResultStreamModels
import ResultStreamModelsTestHelpers
import RunnerModels
import XCTest

public final class RSTestFinishedTests: XCTestCase {
    func test() {
        check(
            input: RSTestFinishedTestInput.input(
                testName: TestName(className: "Class", methodName: "test_method"),
                duration: 0.4511209726333618
            ),
            equals: RSTestFinished(
                structuredPayload: RSTestFinishedEventPayload(
                    resultInfo: RSStreamedActionResultInfo(resultIndex: 1),
                    test: RSActionTestMetadata(
                        identifier: "Class/test_method()",
                        name: "test_method()",
                        duration: 0.4511209726333618,
                        testStatus: "Success",
                        summaryRef: RSReference(id: "0~KoM-3hFhyt...aneYuQ==")
                    )
                )
            )
        )
    }
}
