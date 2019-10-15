import Foundation
import XCTest

public final class TestQuery {
    private let exceptionName: NSExceptionName = NSExceptionName("TestQueryException")
  
    private struct TestInfo: Encodable {
        let className: String
        let path: String
        let testMethods: [String]
    }
    
    private let outputPath: String
    
    init(outputPath: String) {
        self.outputPath = outputPath
    }
    
    func export() {
        var testCases = [TestInfo]()
        
        for suiteInfo in TestGetter().allTests() {
            let testCaseInstance = suiteInfo.testCaseInstance
            let testCaseType = String(describing: type(of: testCaseInstance))
            
            testCases.append(
                TestInfo(
                    className: testCaseType,
                    path: "",
                    testMethods: suiteInfo.testMethods
                )
            )
        }
        
        output(testCases)
    }
    
    private func output(_ content: [TestInfo]) {
        let coder = JSONEncoder()
        if #available(iOS 11.0, *) {
            coder.outputFormatting = [.prettyPrinted, .sortedKeys]
        } else {
            coder.outputFormatting = [.prettyPrinted]
        }
        guard let data = try? coder.encode(content) else {
            let reason = "Unable to encode test info array"
            print(reason)
            XCTFail(reason)
            return
        }
        do {
            try data.write(to: URL(fileURLWithPath: outputPath), options: Data.WritingOptions.atomic)
        } catch let error {
            let reason = "Failed to dump runtime tests into '\(outputPath)': \(error)"
            print(reason)
            let exception = NSException(
              name: exceptionName,
              reason: reason,
              userInfo: nil
            )
            exception.raise()
        }
    }
}
