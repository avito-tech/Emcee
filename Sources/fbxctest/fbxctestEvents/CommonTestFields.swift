import Foundation

public protocol CommonTestFields {
    var testModuleName: String { get }
    var testClassName: String { get }
    var testMethodName: String { get }
}

public extension CommonTestFields {
    var testName: String {
        return testClassName + "/" + testMethodName
    }
}
