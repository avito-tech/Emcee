import Foundation
import ResultStreamModels
import RunnerModels

extension RSTestFailureIssueSummary {
    func testException() -> TestException {
        let fileLine = documentLocationInCreatingWorkspace?.fileLine() ?? (file: "Unknown", line: 0)
        return TestException(
            reason: message.stringValue,
            filePathInProject: fileLine.file,
            lineNumber: Int32(fileLine.line)
        )
    }
}
