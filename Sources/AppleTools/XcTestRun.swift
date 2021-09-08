import Foundation

public struct XcTestRun: Equatable {

    /// Xcode tests target name. This could be any possilbe value in case if this is unknown.
    public let testTargetName: String

    public let bundleIdentifiersForCrashReportEmphasis: [String]

    /// Paths to all apps UI test can access, including uiTargetAppPath
    public let dependentProductPaths: [String]

    /// A path to the test bundle to be tested
    public let testBundlePath: String

    /// A path to the test host.
    /// For framework tests, this should be a path to the xctest command line tool.
    /// For application hosted tests, this should be a path the application host.
    /// For UI tests, this should be a path to the test runner application that the UI test target produces.
    public let testHostPath: String

    /// Bundle id of test host app, e.g. com.company.SomeApp or com.apple.test.SomeAppUITests-Runner
    public let testHostBundleIdentifier: String

    /// A path to the target application for UI tests. The parameter is mandatory for UI tests only.
    public let uiTargetAppPath: String?

    /// The environment variables from the scheme test action that xcodebuild will provide to the test host process.
    public let environmentVariables: [String: String]

    /// The command line arguments from the scheme test action that xcodebuild will provide to the test host process.
    public let commandLineArguments: [String]

    /// The environment variables that xcodebuild will provide to the target application during UI tests.
    public let uiTargetAppEnvironmentVariables: [String: String]

    /// The command line arguments that xcodebuild will provide to the target application during UI tests.
    public let uiTargetAppCommandLineArguments: [String]

    /// Should Main Thread Checker be enabled or not.
    public let uiTargetAppMainThreadCheckerEnabled: Bool

    /// An array of test identifiers that xcodebuild should exclude from the test run.
    /// Identifiers for both Swift and Objective-C tests are:
    /// Test-Class-Name[/Test-Method-Name]
    public let skipTestIdentifiers: [String]

    /// An array of test identifiers that xcodebuild should include in the test run.
    /// All other tests will be excluded from the test run.
    /// Identifiers for both Swift and Objective-C tests are:
    /// Test-Class-Name[/Test-Method-Name]
    public let onlyTestIdentifiers: [String]

    /// Additional testing environment variables that xcodebuild will provide to the TestHostPath process.
    public let testingEnvironmentVariables: [String: String]

    /// Indicates this is UI test run.
    public let isUITestBundle: Bool

    /// Indicates this is application test run.
    public let isAppHostedTestBundle: Bool

    /// true for Xcode UI tests.
    public let isXCTRunnerHostedTestBundle: Bool
    
    /// The module name of this test target, as specified by the target's `PRODUCT_MODULE_NAME` build setting in Xcode.
    /// `.` and `-` symbols usually are replaced with `_`, e.g. `Some.SDK` becomes `Some_SDK`.
    public let testTargetProductModuleName: String
    
    public let systemAttachmentLifetime: XcTestRunAttachmentLifetime
    
    public let userAttachmentLifetime: XcTestRunAttachmentLifetime

    public init(
        testTargetName: String,
        bundleIdentifiersForCrashReportEmphasis: [String],
        dependentProductPaths: [String],
        testBundlePath: String,
        testHostPath: String,
        testHostBundleIdentifier: String,
        uiTargetAppPath: String?,
        environmentVariables: [String: String],
        commandLineArguments: [String],
        uiTargetAppEnvironmentVariables: [String: String],
        uiTargetAppCommandLineArguments: [String],
        uiTargetAppMainThreadCheckerEnabled: Bool,
        skipTestIdentifiers: [String],
        onlyTestIdentifiers: [String],
        testingEnvironmentVariables: [String: String],
        isUITestBundle: Bool,
        isAppHostedTestBundle: Bool,
        isXCTRunnerHostedTestBundle: Bool,
        testTargetProductModuleName: String,
        systemAttachmentLifetime: XcTestRunAttachmentLifetime,
        userAttachmentLifetime: XcTestRunAttachmentLifetime
    ) {
        self.testTargetName = testTargetName
        self.bundleIdentifiersForCrashReportEmphasis = bundleIdentifiersForCrashReportEmphasis
        self.dependentProductPaths = dependentProductPaths
        self.testBundlePath = testBundlePath
        self.testHostPath = testHostPath
        self.testHostBundleIdentifier = testHostBundleIdentifier
        self.uiTargetAppPath = uiTargetAppPath
        self.environmentVariables = environmentVariables
        self.commandLineArguments = commandLineArguments
        self.uiTargetAppEnvironmentVariables = uiTargetAppEnvironmentVariables
        self.uiTargetAppCommandLineArguments = uiTargetAppCommandLineArguments
        self.uiTargetAppMainThreadCheckerEnabled = uiTargetAppMainThreadCheckerEnabled
        self.skipTestIdentifiers = skipTestIdentifiers
        self.onlyTestIdentifiers = onlyTestIdentifiers
        self.testingEnvironmentVariables = testingEnvironmentVariables
        self.isUITestBundle = isUITestBundle
        self.isAppHostedTestBundle = isAppHostedTestBundle
        self.isXCTRunnerHostedTestBundle = isXCTRunnerHostedTestBundle
        self.testTargetProductModuleName = testTargetProductModuleName
        self.systemAttachmentLifetime = systemAttachmentLifetime
        self.userAttachmentLifetime = userAttachmentLifetime
    }
}
