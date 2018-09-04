import Foundation

public enum TestType: String {
    
    /** Requires Simulator. Test bundle is loaded by separate process (Runner.app), which uses testmanagerd to control host app. */
    case uiTest
    
    /** Requires Simulator. Test bundle is loaded by host application, having direct access to objects, memory etc. of the host app. */
    case appTest
    
    /** Does not require Simulator. Uses fake simulator environment - "shimulator", fast to run */
    case logicTest
}
