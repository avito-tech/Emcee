import Foundation

/// Represents a test name in a format "ClassName/testMethodName".
public final class TestName: CustomStringConvertible, Codable, Hashable {
    public let className: String
    public let methodName: String

    public init(className: String, methodName: String) {
        self.className = className
        self.methodName = methodName
    }
    
    public var stringValue: String {
        return className + "/" + methodName
    }
    
    public var description: String {
        return stringValue
    }
    
    enum CodingKeys: String, CodingKey {
        case className
        case methodName
    }

    public init(from decoder: Decoder) throws {
        let testName: TestName
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            testName = TestName(
                className: try container.decode(String.self, forKey: .className),
                methodName: try container.decode(String.self, forKey: .methodName)
            )
        } catch {
            let container = try decoder.singleValueContainer()
            testName = try TestName.createFromTestNameString(
                stringValue: try container.decode(String.self)
            )
        }
        self.className = testName.className
        self.methodName = testName.methodName
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(className, forKey: .className)
        try container.encode(methodName, forKey: .methodName)
    }

    public enum TestNameError: Error, CustomStringConvertible {
        case unableToExctractClassAndMethodNames(stringValue: String)

        public var description: String {
            switch self {
            case .unableToExctractClassAndMethodNames(let stringValue):
                 return "Unable to extract class or method from the string value '\(stringValue)'. It should have 'ClassName/testMethod' format."
            }
        }
    }

    private static func createFromTestNameString(stringValue: String) throws -> TestName {
        let components = stringValue.components(separatedBy: "/")
        guard components.count == 2, let className = components.first, let methodName = components.last else {
            throw TestNameError.unableToExctractClassAndMethodNames(stringValue: stringValue)
        }
        return TestName(className: className, methodName: methodName)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(className)
        hasher.combine(methodName)
    }

    public static func == (left: TestName, right: TestName) -> Bool {
        return left.className == right.className
            && left.methodName == right.methodName
    }
}

