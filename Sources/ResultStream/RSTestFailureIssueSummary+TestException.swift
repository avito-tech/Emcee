import CommonTestModels
import Foundation
import ResultStreamModels

extension RSTestFailureIssueSummary {
    public func testException() -> TestException {
        var testName: TestName? = nil
        /// testCaseName - `ClassName.testMethodName()`
        if let testCaseName = testCaseName {
            let components = testCaseName.stringValue.components(separatedBy: ".")
            if components.count == 2, components[1].count > 3 {
                testName = TestName(className: components[0], methodName: String(components[1].dropLast(2)))
            }
        }
        
        let fileLine = documentLocationInCreatingWorkspace?.fileLine() ?? (file: "Unknown", line: 0)
        return TestException(
            reason: message.stringValue,
            filePathInProject: fileLine.file,
            lineNumber: Int32(fileLine.line),
            relatedTestName: testName
        )
    }
}
