import Foundation
import RunnerModels

public protocol CommonTestFields {
    var testModuleName: String { get }
    var testClassName: String { get }
    var testMethodName: String { get }
}

public extension CommonTestFields {
    var testName: TestName {
        return TestName(className: testClassName, methodName: testMethodName)
    }
}
