import Foundation

class FbXcTestEventClassNameParser {
    private init() {}
    
    /// SomeModule.TestClass -> TestClass
    static func className(moduledClassName: String) -> String {
        let components = moduledClassName.components(separatedBy: ".")
        guard components.count == 2 else { return moduledClassName }
        // first component contains a module name, second - class name
        return components[1]
    }
    
    /// SomeModule.TestClass -> SomeModule
    static func moduleName(moduledClassName: String) -> String {
        let components = moduledClassName.components(separatedBy: ".")
        guard components.count == 2 else { return "" }
        // first component contains a module name, second - class name
        return components[0]
    }
}
