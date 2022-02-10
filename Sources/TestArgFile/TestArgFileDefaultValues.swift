import AppleTestModels
import BuildArtifacts
import CommonTestModels
import DeveloperDirModels
import EmceeExtensions
import Foundation
import MetricsExtensions
import PluginSupport
import QueueModels
import ScheduleStrategy
import SimulatorPoolModels
import WorkerCapabilitiesModels

public enum TestArgFileDefaultValues {
    public static let developerDir = DeveloperDir.current
    public static let environment: [String: String] = [:]
    public static let userInsertedLibraries: [String] = []
    public static let numberOfRetries: UInt = 1
    public static let testRetryMode: TestRetryMode = .retryThroughQueue
    public static let pluginLocations: Set<AppleTestPluginLocation> = []
    public static func createAutomaticJobId() -> JobId {
        JobId(value: "automaticJobId_" + String.randomString(length: 10))
    }
    public static let priority = Priority.medium
    public static let scheduleStrategy = ScheduleStrategy(
        testSplitterType: .progressive
    )
    public static let simulatorOperationTimeouts = SimulatorOperationTimeouts(
        create: 60,
        boot: 180,
        delete: 30,
        shutdown: 30,
        automaticSimulatorShutdown: 300,
        automaticSimulatorDelete: 300
    )
    public static let simulatorSettings = SimulatorSettings(
        simulatorLocalizationSettings: SimulatorLocalizationSettings(
            localeIdentifier: "ru_US",
            keyboards: ["ru_RU@sw=Russian;hw=Automatic", "en_US@sw=QWERTY;hw=Automatic"],
            passcodeKeyboards: ["ru_RU@sw=Russian;hw=Automatic", "en_US@sw=QWERTY;hw=Automatic"],
            languages: ["ru-US", "en", "ru-RU"],
            addingEmojiKeybordHandled: true,
            enableKeyboardExpansion: true,
            didShowInternationalInfoAlert: true,
            didShowContinuousPathIntroduction: true,
            didShowGestureKeyboardIntroduction: true
        ),
        simulatorKeychainSettings: SimulatorKeychainSettings(
            rootCerts: []
        ),
        watchdogSettings: WatchdogSettings(bundleIds: [], timeout: 20)
    )
    public static let testTimeoutConfiguration = TestTimeoutConfiguration(
        singleTestMaximumDuration: 180,
        testRunnerMaximumSilenceDuration: 60
    )
    public static let testAttachmentLifetime: TestAttachmentLifetime = .deleteOnSuccess
    public static let workerCapabilityRequirements: Set<WorkerCapabilityRequirement> = []
    public static let analyticsConfiguration = AnalyticsConfiguration()
    public static let logCapturingMode = LogCapturingMode.onlyCrashLogs
    public static let runnerWasteCleanupPolicy = RunnerWasteCleanupPolicy.clean
}
