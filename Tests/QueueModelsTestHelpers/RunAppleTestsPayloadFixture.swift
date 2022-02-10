import AppleTestModels
import AppleTestModelsTestHelpers
import CommonTestModels
import CommonTestModelsTestHelpers
import Foundation
import QueueModels

public final class RunAppleTestsPayloadFixture {
    public var testEntries: [TestEntry]
    public var testsConfiguration: AppleTestConfiguration

    public init(
        testEntries: [TestEntry] = [
            TestEntryFixtures.testEntry(),
        ],
        testsConfiguration: AppleTestConfiguration = AppleTestConfigurationFixture().appleTestConfiguration()
    ) {
        self.testEntries = testEntries
        self.testsConfiguration = testsConfiguration
    }
    
    public func with(testEntries: [TestEntry]) -> Self {
        self.testEntries = testEntries
        return self
    }
    
    public func with(testsConfiguration: AppleTestConfiguration) -> Self {
        self.testsConfiguration = testsConfiguration
        return self
    }
    
    public func runAppleTestsPayload() -> RunAppleTestsPayload {
        RunAppleTestsPayload(testEntries: testEntries, testsConfiguration: testsConfiguration)
    }
}
