import AndroidEmulatorModels
import BuildArtifacts
import CommonTestModels
import Foundation
import TestDestination

public final class AndroidTestConfiguration: Codable, Hashable {
    public let buildArtifacts: AndroidBuildArtifacts
    public let deviceType: String
    public let sdkVersion: Int
    public let testExecutionBehavior: TestExecutionBehavior
    public let testMaximumDuration: TimeInterval

    public init(
        buildArtifacts: AndroidBuildArtifacts,
        deviceType: String,
        sdkVersion: Int,
        testExecutionBehavior: TestExecutionBehavior,
        testMaximumDuration: TimeInterval
    ) {
        self.buildArtifacts = buildArtifacts
        self.deviceType = deviceType
        self.sdkVersion = sdkVersion
        self.testExecutionBehavior = testExecutionBehavior
        self.testMaximumDuration = testMaximumDuration
    }
    
    public var testDestination: TestDestination {
        TestDestination.androidEmulator(
            deviceType: deviceType,
            sdkVersion: sdkVersion
        )
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(buildArtifacts)
        hasher.combine(deviceType)
        hasher.combine(sdkVersion)
        hasher.combine(testExecutionBehavior)
        hasher.combine(testMaximumDuration)
    }
    
    public static func == (lhs: AndroidTestConfiguration, rhs: AndroidTestConfiguration) -> Bool {
        return true
        && lhs.buildArtifacts == rhs.buildArtifacts
        && lhs.deviceType == rhs.deviceType
        && lhs.sdkVersion == rhs.sdkVersion
        && lhs.testExecutionBehavior == rhs.testExecutionBehavior
        && lhs.testMaximumDuration == rhs.testMaximumDuration
    }
}
