import AndroidTestModels
import BuildArtifacts
import BuildArtifactsTestHelpers
import CommonTestModels
import CommonTestModelsTestHelpers
import Foundation

public final class AndroidTestConfigurationFixture {
    public var buildArtifacts: AndroidBuildArtifacts
    public var deviceType: String
    public var sdkVersion: Int
    public var testExecutionBehavior: TestExecutionBehavior
    public var testMaximumDuration: TimeInterval
    
    public init(
        buildArtifacts: AndroidBuildArtifacts = AndroidBuildArtifactsFixture().androidBuildArtifacts(),
        deviceType: String = "deviceType",
        sdkVersion: Int = 23,
        testExecutionBehavior: TestExecutionBehavior = TestExecutionBehaviorFixtures().testExecutionBehavior(),
        testMaximumDuration: TimeInterval = 60
    ) {
        self.buildArtifacts = buildArtifacts
        self.deviceType = deviceType
        self.sdkVersion = sdkVersion
        self.testExecutionBehavior = testExecutionBehavior
        self.testMaximumDuration = testMaximumDuration
    }
    
    public func with(buildArtifacts: AndroidBuildArtifacts) -> Self {
        self.buildArtifacts = buildArtifacts
        return self
    }
    
    public func with(deviceType: String) -> Self {
        self.deviceType = deviceType
        return self
    }
    
    public func with(sdkVersion: Int) -> Self {
        self.sdkVersion = sdkVersion
        return self
    }
    
    public func with(testExecutionBehavior: TestExecutionBehavior) -> Self {
        self.testExecutionBehavior = testExecutionBehavior
        return self
    }
    
    public func with(testMaximumDuration: TimeInterval) -> Self {
        self.testMaximumDuration = testMaximumDuration
        return self
    }
    
    public func androidTestConfiguration() -> AndroidTestConfiguration {
        AndroidTestConfiguration(
            buildArtifacts: buildArtifacts,
            deviceType: deviceType,
            sdkVersion: sdkVersion,
            testExecutionBehavior: testExecutionBehavior,
            testMaximumDuration: testMaximumDuration
        )
    }
}
