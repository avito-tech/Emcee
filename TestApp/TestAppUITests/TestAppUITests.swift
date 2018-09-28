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
    
    func testWritingToTestWorkingDir() {
        guard let testWorkingDir = ProcessInfo.processInfo.environment["EMCEE_TESTS_WORKING_DIRECTORY"] else {
            XCTFail("EMCEE_TESTS_WORKING_DIRECTORY was not set")
            return
        }
        
        let file = (testWorkingDir as NSString).appendingPathComponent("test_artifact.txt")
        let contents = "contents"
        do {
            try contents.write(to: URL(fileURLWithPath: file), atomically: true, encoding: .utf8)
        } catch {
            XCTFail("Failed to write file: \(error)")
        }
    }
}
