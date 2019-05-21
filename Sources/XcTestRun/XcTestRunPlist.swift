import Foundation

public final class XcTestRunPlist {
    private let xcTestRun: XcTestRun

    public init(xcTestRun: XcTestRun) {
        self.xcTestRun = xcTestRun
    }

    public func createPlistData() throws -> Data {
        let contents = createPlistDict()
        return try PropertyListSerialization.data(fromPropertyList: contents, format: .xml, options: 0)
    }

    private func createPlistDict() -> NSDictionary {
        let dictionary = NSMutableDictionary()
        dictionary["BundleIdentifiersForCrashReportEmphasis"] = xcTestRun.bundleIdentifiersForCrashReportEmphasis
        dictionary["DependentProductPaths"] = xcTestRun.dependentProductPaths
        dictionary["TestBundlePath"] = xcTestRun.testBundlePath
        dictionary["TestHostPath"] = xcTestRun.testHostPath
        dictionary["TestHostBundleIdentifier"] = xcTestRun.testHostBundleIdentifier
        if let uiTargetAppPath = xcTestRun.uiTargetAppPath {
            dictionary["UiTargetAppPath"] = uiTargetAppPath
        }
        dictionary["EnvironmentVariables"] = xcTestRun.environmentVariables
        dictionary["CommandLineArguments"] = xcTestRun.commandLineArguments
        dictionary["UITargetAppEnvironmentVariables"] = xcTestRun.uiTargetAppEnvironmentVariables
        dictionary["UITargetAppCommandLineArguments"] = xcTestRun.uiTargetAppCommandLineArguments
        dictionary["UITargetAppMainThreadCheckerEnabled"] = xcTestRun.uiTargetAppMainThreadCheckerEnabled
        dictionary["SkipTestIdentifiers"] = xcTestRun.skipTestIdentifiers
        dictionary["OnlyTestIdentifiers"] = xcTestRun.onlyTestIdentifiers
        dictionary["TestingEnvironmentVariables"] = xcTestRun.testingEnvironmentVariables
        dictionary["IsUITestBundle"] = xcTestRun.isUITestBundle
        dictionary["IsAppHostedTestBundle"] = xcTestRun.isAppHostedTestBundle
        dictionary["IsXCTRunnerHostedTestBundle"] = xcTestRun.isXCTRunnerHostedTestBundle
        return NSDictionary(
            object: dictionary,
            forKey: xcTestRun.testTargetName as NSString
        )
    }
}
