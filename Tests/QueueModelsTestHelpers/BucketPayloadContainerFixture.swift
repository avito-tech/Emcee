import Foundation
import QueueModels
import XCTest

public final class BucketPayloadContainerFixture {
    public static func runAppleTests(
        runAppleTestsPayload: RunAppleTestsPayload = RunAppleTestsPayloadFixture().runAppleTestsPayload()
    ) -> BucketPayloadContainer {
        return .runAppleTests(runAppleTestsPayload)
    }
    
    public static func runAndroidTests(
        runAndroidTestsPayload: RunAndroidTestsPayload = RunAndroidTestsPayloadFixture().runAndroidTestsPayload()
    ) -> BucketPayloadContainer {
        return .runAndroidTests(runAndroidTestsPayload)
    }
}
