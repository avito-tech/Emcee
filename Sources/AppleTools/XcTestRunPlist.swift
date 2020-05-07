import Foundation

public final class XcTestRunPlist {
    public let xcTestRun: XcTestRun

    public init(xcTestRun: XcTestRun) {
        self.xcTestRun = xcTestRun
    }

    public func createPlistData() throws -> Data {
        let contents = createPlistDict()
        return try PropertyListSerialization.data(fromPropertyList: contents, format: .xml, options: 0)
    }
    
    private enum Keys: String {
        case BundleIdentifiersForCrashReportEmphasis
        case DependentProductPaths
        case TestBundlePath
        case TestHostPath
        case TestHostBundleIdentifier
        case UITargetAppPath
        case EnvironmentVariables
        case CommandLineArguments
        case UITargetAppEnvironmentVariables
        case UITargetAppCommandLineArguments
        case UITargetAppMainThreadCheckerEnabled
        case SkipTestIdentifiers
        case OnlyTestIdentifiers
        case TestingEnvironmentVariables
        case IsUITestBundle
        case IsAppHostedTestBundle
        case IsXCTRunnerHostedTestBundle
        case ProductModuleName
    }

    private func createPlistDict() -> NSDictionary {
        let dictionary = NSMutableDictionary()
        dictionary[Keys.BundleIdentifiersForCrashReportEmphasis.rawValue] = xcTestRun.bundleIdentifiersForCrashReportEmphasis
        dictionary[Keys.DependentProductPaths.rawValue] = xcTestRun.dependentProductPaths
        dictionary[Keys.TestBundlePath.rawValue] = xcTestRun.testBundlePath
        dictionary[Keys.TestHostPath.rawValue] = xcTestRun.testHostPath
        dictionary[Keys.TestHostBundleIdentifier.rawValue] = xcTestRun.testHostBundleIdentifier
        if let uiTargetAppPath = xcTestRun.uiTargetAppPath {
            dictionary[Keys.UITargetAppPath.rawValue] = uiTargetAppPath
        }
        dictionary[Keys.EnvironmentVariables.rawValue] = xcTestRun.environmentVariables
        dictionary[Keys.CommandLineArguments.rawValue] = xcTestRun.commandLineArguments
        dictionary[Keys.UITargetAppEnvironmentVariables.rawValue] = xcTestRun.uiTargetAppEnvironmentVariables
        dictionary[Keys.UITargetAppCommandLineArguments.rawValue] = xcTestRun.uiTargetAppCommandLineArguments
        dictionary[Keys.UITargetAppMainThreadCheckerEnabled.rawValue] = xcTestRun.uiTargetAppMainThreadCheckerEnabled
        dictionary[Keys.SkipTestIdentifiers.rawValue] = xcTestRun.skipTestIdentifiers
        dictionary[Keys.OnlyTestIdentifiers.rawValue] = xcTestRun.onlyTestIdentifiers
        dictionary[Keys.TestingEnvironmentVariables.rawValue] = xcTestRun.testingEnvironmentVariables
        dictionary[Keys.IsUITestBundle.rawValue] = xcTestRun.isUITestBundle
        dictionary[Keys.IsAppHostedTestBundle.rawValue] = xcTestRun.isAppHostedTestBundle
        dictionary[Keys.IsXCTRunnerHostedTestBundle.rawValue] = xcTestRun.isXCTRunnerHostedTestBundle
        dictionary[Keys.ProductModuleName.rawValue] = xcTestRun.testTargetProductModuleName
        return NSDictionary(
            object: dictionary,
            forKey: xcTestRun.testTargetName as NSString
        )
    }
    
    public static func readPlist(data: Data) throws -> XcTestRunPlist {
        enum ReadingError: Error {
            case unexpectedFormat
            case missingValue(key: Keys)
        }
        func readValue<T>(key: Keys, contents: NSDictionary) throws -> T {
            if let value = contents[key.rawValue] as? T {
                return value
            }
            throw ReadingError.missingValue(key: key)
        }
        func readOptionalValue<T>(key: Keys, contents: NSDictionary) throws -> T? {
            if contents[key.rawValue] == nil {
                return nil
            }
            return try readValue(key: key, contents: contents)
        }
        
        let plist = try PropertyListSerialization.propertyList(
            from: data,
            options: [],
            format: nil
        )
        guard let plistRootContents = plist as? NSDictionary else {
            throw ReadingError.unexpectedFormat
        }
        guard let testTargetName = plistRootContents.allKeys.first as? String else {
            throw ReadingError.unexpectedFormat
        }
        guard let plistContents = plistRootContents[testTargetName] as? NSDictionary else {
            throw ReadingError.unexpectedFormat
        }
        
        return XcTestRunPlist(
            xcTestRun: XcTestRun(
                testTargetName: testTargetName,
                bundleIdentifiersForCrashReportEmphasis: try readValue(key: .BundleIdentifiersForCrashReportEmphasis, contents: plistContents),
                dependentProductPaths: try readValue(key: .DependentProductPaths, contents: plistContents),
                testBundlePath: try readValue(key: .TestBundlePath, contents: plistContents),
                testHostPath: try readValue(key: .TestHostPath, contents: plistContents),
                testHostBundleIdentifier: try readValue(key: .TestHostBundleIdentifier, contents: plistContents),
                uiTargetAppPath: try readOptionalValue(key: .UITargetAppPath, contents: plistContents),
                environmentVariables: try readValue(key: .EnvironmentVariables, contents: plistContents),
                commandLineArguments: try readValue(key: .CommandLineArguments, contents: plistContents),
                uiTargetAppEnvironmentVariables: try readValue(key: .UITargetAppEnvironmentVariables, contents: plistContents),
                uiTargetAppCommandLineArguments: try readValue(key: .UITargetAppCommandLineArguments, contents: plistContents),
                uiTargetAppMainThreadCheckerEnabled: try readValue(key: .UITargetAppMainThreadCheckerEnabled, contents: plistContents),
                skipTestIdentifiers: try readValue(key: .SkipTestIdentifiers, contents: plistContents),
                onlyTestIdentifiers: try readValue(key: .OnlyTestIdentifiers, contents: plistContents),
                testingEnvironmentVariables: try readValue(key: .TestingEnvironmentVariables, contents: plistContents),
                isUITestBundle: try readValue(key: .IsUITestBundle, contents: plistContents),
                isAppHostedTestBundle: try readValue(key: .IsAppHostedTestBundle, contents: plistContents),
                isXCTRunnerHostedTestBundle: try readValue(key: .IsXCTRunnerHostedTestBundle, contents: plistContents),
                testTargetProductModuleName: try readValue(key: .ProductModuleName, contents: plistContents)
            )
        )
    }
}
