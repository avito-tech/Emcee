import CommonTestModels
import Foundation

public extension TestName {
    /// Converts objc test name in form of `-[ModuleName.TestClassName testMethod]`  into `TestName`
    /// - Parameter string: objc test name in form of `-[ModuleName.TestClassName testMethod]`
    static func parseObjCTestName(string: String) throws -> TestName {
        struct UnparsableTestName: Error, CustomStringConvertible {
            let value: String
            var description: String {
                return "Cannot parse test name from '\(value)'. Expected format: -[ModuleName.ClassName testMethod]"
            }
        }
        
        guard string.hasPrefix("-["), string.hasSuffix("]") else { throw UnparsableTestName(value: string) }
        
        let components = string.dropFirst(2).dropLast(1).split(separator: " ", omittingEmptySubsequences: false)
        guard components.count == 2 else { throw UnparsableTestName(value: string) }
        
        let moduleClassComponents = components[0].split(separator: ".", omittingEmptySubsequences: false)
        let testMethodNameComponent = components[1]
        
        let className: Substring
        
        switch moduleClassComponents.count {
        case 2:
            let moduleName = moduleClassComponents[0]
            guard !moduleName.isEmpty else { throw UnparsableTestName(value: string) }
            className = moduleClassComponents[1]
        case 1:
            className = moduleClassComponents[0]
        default:
            throw UnparsableTestName(value: string)
        }
        
        guard !className.isEmpty else { throw UnparsableTestName(value: string) }
        
        return TestName(
            className: String(className),
            methodName: String(testMethodNameComponent)
        )
    }
}
