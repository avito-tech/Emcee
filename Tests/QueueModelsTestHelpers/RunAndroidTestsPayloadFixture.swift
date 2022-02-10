import AndroidTestModels
import AndroidTestModelsTestHelpers
import CommonTestModels
import CommonTestModelsTestHelpers
import Foundation
import QueueModels
import XCTest

public final class RunAndroidTestsPayloadFixture {
    public var testEntries: [TestEntry]
    public var testConfiguration: AndroidTestConfiguration
    
    public init(
        testEntries: [TestEntry] = [
            TestEntryFixtures.testEntry(),
        ],
        testConfiguration: AndroidTestConfiguration = AndroidTestConfigurationFixture().androidTestConfiguration()
    ) {
        self.testEntries = testEntries
        self.testConfiguration = testConfiguration
    }
    
    public func with(testEntries: [TestEntry]) -> Self {
        self.testEntries = testEntries
        return self
    }
    
    public func with(testConfiguration: AndroidTestConfiguration) -> Self {
        self.testConfiguration = testConfiguration
        return self
    }

    public func runAndroidTestsPayload() -> RunAndroidTestsPayload {
        RunAndroidTestsPayload(testEntries: testEntries, testConfiguration: testConfiguration)
    }
}
