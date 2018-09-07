import XCTest

class TestAppUITests: XCTestCase {
        
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }
    
    override func tearDown() {
        XCUIApplication().terminate()
    }
    
    func testQuickTest() {
        XCUIApplication().launch()
        sleep(20)
    }
    
    func testSlowTest() {
        XCUIApplication().launch()
        sleep(20)
    }
    
    func testAlwaysSuccess() {
        sleep(10)
    }
    
    func testAlwaysFails() {
        sleep(10)
        XCTFail("I will always fail")
    }
}
