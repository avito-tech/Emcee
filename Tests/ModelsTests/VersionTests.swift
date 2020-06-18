import Models
import XCTest

class VersionTests: XCTestCase {
    func test___compare_array___different_count() {
        let long: [Version] = ["V1", "V2"]
        let short: [Version] = ["V1"]
        
        XCTAssertTrue(long > short)
        XCTAssertFalse(long < short)
        XCTAssertTrue(short < long)
        XCTAssertFalse(short > long)
    }
    
    func test___compare_array___bigger_verion_name() {
        let big: [Version] = ["V2"]
        let small: [Version] = ["V1"]
        
        XCTAssertTrue(big > small)
        XCTAssertFalse(big < small)
        XCTAssertTrue(small < big)
        XCTAssertFalse(small > big)
    }
    
    func test___compare_array___position_independent() {
        let big: [Version] = ["V1", "V3"]
        let small: [Version] = ["V2", "V1"]
        
        XCTAssertTrue(big > small)
        XCTAssertFalse(big < small)
        XCTAssertTrue(small < big)
        XCTAssertFalse(small > big)
    }
}
