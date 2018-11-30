import Foundation

/// Represents --test-arg-file file contents which describes all tests that should be ran.
public struct TestArgFile: Decodable {
    public struct Entry: Decodable {
        public let testToRun: TestToRun
        public let testDestination: TestDestination
        public let numberOfRetries: UInt
        
        public init(testToRun: TestToRun, testDestination: TestDestination, numberOfRetries: UInt) {
            self.testToRun = testToRun
            self.testDestination = testDestination
            self.numberOfRetries = numberOfRetries
        }
    }
    
    public let entries: [Entry]
    
    public init(entries: [Entry]) {
        self.entries = entries
    }
}
