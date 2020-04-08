import Foundation
import Runner
import TestHelpers
import XCTest

final class TestNameParserTests: XCTestCase {
    func test___components() {
        let components = assertDoesNotThrow {
            try TestNameParser.components(moduledTestName: "Module.ClassName.testMethod")
        }
        XCTAssertEqual(components.module, "Module")
        XCTAssertEqual(components.className, "ClassName")
        XCTAssertEqual(components.methodName, "testMethod")
    }
    
    func test___invalid_components() {
        assertThrows {
            _ = try TestNameParser.components(moduledTestName: "A.B")
        }
        assertThrows {
            _ = try TestNameParser.components(moduledTestName: "A")
        }
    }
    
    func test___class_name_from_moduled_class_name() {
        XCTAssertEqual(TestNameParser.className(moduledClassName: "Module.Class"), "Class")
        XCTAssertEqual(TestNameParser.className(moduledClassName: "Class"), "Class")
    }
    
    func test___module_name_from_moduled_class_name() {
        XCTAssertEqual(TestNameParser.moduleName(moduledClassName: "Module.Class"), "Module")
        XCTAssertEqual(TestNameParser.moduleName(moduledClassName: "Class"), "")
    }
}
