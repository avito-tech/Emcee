import Foundation

public final class TestNameParser {
    private init() {}
    
    public enum TestNameParserError: Error, CustomStringConvertible {
        case incorrectInput(String)
        
        public var description: String {
            switch self {
            case .incorrectInput(let input):
                return "Can't extract module, class name and method name from '\(input)'. Expected format: ModuleName.ClassName.methodName"
            }
        }
    }
    
    /// SomeModule.TestClass.testMethod -> SomeModule.TestClass
    public static func components(moduledTestName: String) throws -> (module: String, className: String, methodName: String) {
        let components = moduledTestName.components(separatedBy: ".")
        guard components.count == 3 else {
            throw TestNameParserError.incorrectInput(moduledTestName)
        }
        return (module: components[0], className: components[1], methodName: components[2])
    }
    
    /// SomeModule.TestClass -> TestClass
    public static func className(moduledClassName: String) -> String {
        let components = moduledClassName.components(separatedBy: ".")
        guard components.count == 2 else { return moduledClassName }
        // first component contains a module name, second - class name
        return components[1]
    }
    
    /// SomeModule.TestClass -> SomeModule
    public static func moduleName(moduledClassName: String) -> String {
        let components = moduledClassName.components(separatedBy: ".")
        guard components.count == 2 else { return "" }
        // first component contains a module name, second - class name
        return components[0]
    }
}
