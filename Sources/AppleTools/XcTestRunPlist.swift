import Foundation
import PlistLib

public final class XcTestRunPlist {
    public let xcTestRun: XcTestRun

    public init(xcTestRun: XcTestRun) {
        self.xcTestRun = xcTestRun
    }

    public func createPlistData() throws -> Data {
        try createPlist().data(format: .xml)
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
        case SystemAttachmentLifetime
        case UserAttachmentLifetime
    }

    private func createPlist() -> Plist {
        let plistContents = RootPlistEntry.dict([
            xcTestRun.testTargetName: .dict([
                Keys.BundleIdentifiersForCrashReportEmphasis.rawValue: .arrayOf(strings: xcTestRun.bundleIdentifiersForCrashReportEmphasis),
                Keys.DependentProductPaths.rawValue: .arrayOf(strings: xcTestRun.dependentProductPaths),
                Keys.TestBundlePath.rawValue: .string(xcTestRun.testBundlePath),
                Keys.TestHostPath.rawValue: .string(xcTestRun.testHostPath),
                Keys.TestHostBundleIdentifier.rawValue: .string(xcTestRun.testHostBundleIdentifier),
                Keys.UITargetAppPath.rawValue: (xcTestRun.uiTargetAppPath == nil ? nil : .string(xcTestRun.uiTargetAppPath!)),
                Keys.EnvironmentVariables.rawValue: .dict(xcTestRun.environmentVariables.mapValues(PlistEntry.string)),
                Keys.CommandLineArguments.rawValue: .arrayOf(strings: xcTestRun.commandLineArguments),
                Keys.UITargetAppEnvironmentVariables.rawValue: .dict(xcTestRun.uiTargetAppEnvironmentVariables.mapValues(PlistEntry.string)),
                Keys.UITargetAppCommandLineArguments.rawValue: .arrayOf(strings: xcTestRun.uiTargetAppCommandLineArguments),
                Keys.UITargetAppMainThreadCheckerEnabled.rawValue: .bool(xcTestRun.uiTargetAppMainThreadCheckerEnabled),
                Keys.SkipTestIdentifiers.rawValue: .arrayOf(strings: xcTestRun.skipTestIdentifiers),
                Keys.OnlyTestIdentifiers.rawValue: .arrayOf(strings: xcTestRun.onlyTestIdentifiers),
                Keys.TestingEnvironmentVariables.rawValue: .dict(xcTestRun.testingEnvironmentVariables.mapValues(PlistEntry.string)),
                Keys.IsUITestBundle.rawValue: .bool(xcTestRun.isUITestBundle),
                Keys.IsAppHostedTestBundle.rawValue: .bool(xcTestRun.isAppHostedTestBundle),
                Keys.IsXCTRunnerHostedTestBundle.rawValue: .bool(xcTestRun.isXCTRunnerHostedTestBundle),
                Keys.ProductModuleName.rawValue: .string(xcTestRun.testTargetProductModuleName),
                Keys.SystemAttachmentLifetime.rawValue: .string(xcTestRun.systemAttachmentLifetime),
                Keys.UserAttachmentLifetime.rawValue: .string(xcTestRun.userAttachmentLifetime)
            ])
        ])
        return Plist(rootPlistEntry: plistContents)
    }
    
    public static func readPlist(data: Data) throws -> XcTestRunPlist {
        enum ReadingError: Error {
            case unexpectedFormat
            case missingValue(key: Keys)
        }
        
        let plist = try Plist.create(fromData: data)
        
        guard let testTargetName = try plist.root.plistEntry.allKeys().first else {
            throw ReadingError.unexpectedFormat
        }
        let testTargetEntry = try plist.root.plistEntry.entry(forKey: testTargetName)
        
        return XcTestRunPlist(
            xcTestRun: XcTestRun(
                testTargetName: testTargetName,
                bundleIdentifiersForCrashReportEmphasis: try testTargetEntry.entry(forKey: Keys.BundleIdentifiersForCrashReportEmphasis.rawValue).toTypedArray(String.self),
                dependentProductPaths: try testTargetEntry.entry(forKey: Keys.DependentProductPaths.rawValue).toTypedArray(String.self),
                testBundlePath: try testTargetEntry.entry(forKey: Keys.TestBundlePath.rawValue).stringValue(),
                testHostPath: try testTargetEntry.entry(forKey: Keys.TestHostPath.rawValue).stringValue(),
                testHostBundleIdentifier: try testTargetEntry.entry(forKey: Keys.TestHostBundleIdentifier.rawValue).stringValue(),
                uiTargetAppPath: try testTargetEntry.optionalEntry(forKey: Keys.UITargetAppPath.rawValue)?.stringValue(),
                environmentVariables: try testTargetEntry.entry(forKey: Keys.EnvironmentVariables.rawValue).toTypedDict(String.self),
                commandLineArguments: try testTargetEntry.entry(forKey: Keys.CommandLineArguments.rawValue).toTypedArray(String.self),
                uiTargetAppEnvironmentVariables: try testTargetEntry.entry(forKey: Keys.UITargetAppEnvironmentVariables.rawValue).toTypedDict(String.self),
                uiTargetAppCommandLineArguments: try testTargetEntry.entry(forKey: Keys.UITargetAppCommandLineArguments.rawValue).toTypedArray(String.self),
                uiTargetAppMainThreadCheckerEnabled: try testTargetEntry.entry(forKey: Keys.UITargetAppMainThreadCheckerEnabled.rawValue).boolValue(),
                skipTestIdentifiers: try testTargetEntry.entry(forKey: Keys.SkipTestIdentifiers.rawValue).toTypedArray(String.self),
                onlyTestIdentifiers: try testTargetEntry.entry(forKey: Keys.OnlyTestIdentifiers.rawValue).toTypedArray(String.self),
                testingEnvironmentVariables: try testTargetEntry.entry(forKey: Keys.TestingEnvironmentVariables.rawValue).toTypedDict(String.self),
                isUITestBundle: try testTargetEntry.entry(forKey: Keys.IsUITestBundle.rawValue).boolValue(),
                isAppHostedTestBundle: try testTargetEntry.entry(forKey: Keys.IsAppHostedTestBundle.rawValue).boolValue(),
                isXCTRunnerHostedTestBundle: try testTargetEntry.entry(forKey: Keys.IsXCTRunnerHostedTestBundle.rawValue).boolValue(),
                testTargetProductModuleName: try testTargetEntry.entry(forKey: Keys.ProductModuleName.rawValue).stringValue(),
                systemAttachmentLifetime: try testTargetEntry.entry(forKey: Keys.SystemAttachmentLifetime.rawValue).stringValue(),
                userAttachmentLifetime: try testTargetEntry.entry(forKey: Keys.UserAttachmentLifetime.rawValue).stringValue()
            )
        )
    }
}

private extension PlistEntry {
    static func arrayOf(strings: [String]) -> PlistEntry {
        .array(strings.map(PlistEntry.string))
    }
}
