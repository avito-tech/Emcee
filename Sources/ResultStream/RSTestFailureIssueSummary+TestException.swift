import Foundation
import ResultStreamModels
import RunnerModels

extension RSTestFailureIssueSummary {
    func testException() -> TestException {
        let fileLine = documentLocationInCreatingWorkspace.fileLine()
        return TestException(
            reason: message.stringValue,
            filePathInProject: fileLine.file,
            lineNumber: Int32(fileLine.line)
        )
    }
}
