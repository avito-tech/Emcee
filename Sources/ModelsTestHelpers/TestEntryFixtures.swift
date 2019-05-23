import Foundation
import Models

public final class TestEntryFixtures {
    public static func testEntry(
        testName: TestName = TestName(
            className: "class",
            methodName: "test"
        ),
        tags: [String] = [],
        caseId: UInt? = nil)
        -> TestEntry
    {
        return TestEntry(
            testName: testName,
            tags: tags,
            caseId: caseId
        )
    }

    public static func testEntry(
        className: String = "class",
        methodName: String = "test",
        tags: [String] = [],
        caseId: UInt? = nil
        ) -> TestEntry
    {
        return testEntry(
            testName: TestName(
                className: className,
                methodName: methodName
            ),
            tags: tags,
            caseId: caseId
        )
    }
}
