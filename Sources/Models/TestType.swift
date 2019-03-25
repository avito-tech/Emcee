import Foundation

public enum TestType: String, Codable, CustomStringConvertible {
    
    /// Test bundle is loaded by separate process (XCTRunner.app). Tests don't have direct access to the host app.
    case uiTest
    
    /// Test bundle is loaded by host application. Tests have direct access to objects, memory etc. of the host app.
    case appTest
    
    /// Does not require Simulator, fast to run.
    case logicTest
    
    public var description: String {
        return rawValue
    }
}
