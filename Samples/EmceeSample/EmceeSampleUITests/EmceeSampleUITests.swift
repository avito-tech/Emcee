import XCTest

class EmceeSampleUITests: XCTestCase {

    func test_0___from_xcui_tests___that_always_succeeds() throws {
        let app = XCUIApplication()
        app.launch()
        
        Thread.sleep(forTimeInterval: 2)
        
        XCTAssert(true)
    }
    
    func test_1___from_xcui_tests___that_always_succeeds() throws {
        let app = XCUIApplication()
        app.launch()
        
        Thread.sleep(forTimeInterval: 2)
        
        XCTAssert(1 == 1)
    }
    
    func test_2___from_xcui_tests___that_always_succeeds() throws {
        let app = XCUIApplication()
        app.launch()
        
        Thread.sleep(forTimeInterval: 2)
        
        XCTAssert([].isEmpty)
    }
    
    func test___from_xcui_tests___that_always_fails() {
        let app = XCUIApplication()
        app.launch()
        
        Thread.sleep(forTimeInterval: 2)
        
        XCTFail("Failure from xcui tests")
    }
    
}
