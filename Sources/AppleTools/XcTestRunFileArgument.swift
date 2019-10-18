import DeveloperDirLocator
import Foundation
import Logging
import Models
import PathLib
import ProcessController
import ResourceLocationResolver
import Runner
import TemporaryStuff
import XcTestRun

public final class XcTestRunFileArgument: SubprocessArgument {
    private let buildArtifacts: BuildArtifacts
    private let developerDirLocator: DeveloperDirLocator
    private let entriesToRun: [TestEntry]
    private let resourceLocationResolver: ResourceLocationResolver
    private let temporaryFolder: TemporaryFolder
    private let testContext: TestContext
    private let testType: TestType

    public init(
        buildArtifacts: BuildArtifacts,
        developerDirLocator: DeveloperDirLocator,
        entriesToRun: [TestEntry],
        resourceLocationResolver: ResourceLocationResolver,
        temporaryFolder: TemporaryFolder,
        testContext: TestContext,
        testType: TestType
    ) {
        self.buildArtifacts = buildArtifacts
        self.developerDirLocator = developerDirLocator
        self.entriesToRun = entriesToRun
        self.resourceLocationResolver = resourceLocationResolver
        self.temporaryFolder = temporaryFolder
        self.testContext = testContext
        self.testType = testType
    }

    public func stringValue() throws -> String {
        let xcTestRun = try createXcTestRun()
        let xcTestRunPlist = XcTestRunPlist(xcTestRun: xcTestRun)

        let plistPath = try temporaryFolder.createFile(
            components: ["xctestrun"],
            filename: UUID().uuidString + ".xctestrun",
            contents: try xcTestRunPlist.createPlistData()
        )
        Logger.debug("xcrun: \(plistPath)")
        return try plistPath.stringValue()
    }

    private func createXcTestRun() throws -> XcTestRun {
        let resolvableXcTestBundle = resourceLocationResolver.resolvable(withRepresentable: buildArtifacts.xcTestBundle.location)
        
        switch testType {
        case .uiTest:
            return try xcTestRunForUiTesting(
                resolvableXcTestBundle: resolvableXcTestBundle
            )
        case .logicTest:
            return try xcTestRunForLogicTesting(
                developerDirPath: try developerDirLocator.path(developerDir: testContext.developerDir),
                resolvableXcTestBundle: resolvableXcTestBundle
            )
        case .appTest:
            return try xcTestRunForApplicationTesting(
                resolvableXcTestBundle: resolvableXcTestBundle
            )
        }
    }

    private func xcTestRunForLogicTesting(
        developerDirPath: AbsolutePath,
        resolvableXcTestBundle: ResolvableResourceLocation
    ) throws -> XcTestRun {
        let testHostPath = developerDirPath.appending(
            components: ["Platforms", "iPhoneSimulator.platform", "Developer", "Library", "Xcode", "Agents", "xctest"]
        )
        let xctestSpecificEnvironment = [
            "DYLD_INSERT_LIBRARIES": "__PLATFORMS__/iPhoneSimulator.platform/Developer/usr/lib/libXCTestBundleInject.dylib",
            "XCInjectBundleInto": testHostPath.pathString
        ]

        return XcTestRun(
            testTargetName: "StubTargetName",
            bundleIdentifiersForCrashReportEmphasis: [],
            dependentProductPaths: [],
            testBundlePath: try resolvableXcTestBundle.resolve().directlyAccessibleResourcePath(),
            testHostPath: testHostPath.pathString,
            testHostBundleIdentifier: "StubBundleId",
            uiTargetAppPath: nil,
            environmentVariables: [:],
            commandLineArguments: [],
            uiTargetAppEnvironmentVariables: [:],
            uiTargetAppCommandLineArguments: [],
            uiTargetAppMainThreadCheckerEnabled: false,
            skipTestIdentifiers: [],
            onlyTestIdentifiers: entriesToRun.map { $0.testName.stringValue },
            testingEnvironmentVariables: xctestSpecificEnvironment.byMergingWith(testContext.environment),
            isUITestBundle: false,
            isAppHostedTestBundle: false,
            isXCTRunnerHostedTestBundle: false
        )
    }

    private func xcTestRunForApplicationTesting(
        resolvableXcTestBundle: ResolvableResourceLocation
    ) throws -> XcTestRun {
        guard let representableAppBundle = buildArtifacts.appBundle else {
            throw RunnerError.noAppBundleDefinedForUiOrApplicationTesting
        }
        let hostAppPath = try resourceLocationResolver.resolvable(resourceLocation: representableAppBundle.resourceLocation).resolve().directlyAccessibleResourcePath()

        return XcTestRun(
            testTargetName: "StubTargetName",
            bundleIdentifiersForCrashReportEmphasis: [],
            dependentProductPaths: [],
            testBundlePath: try resolvableXcTestBundle.resolve().directlyAccessibleResourcePath(),
            testHostPath: hostAppPath,
            testHostBundleIdentifier: "StubBundleId",
            uiTargetAppPath: nil,
            environmentVariables: [:],
            commandLineArguments: [],
            uiTargetAppEnvironmentVariables: [:],
            uiTargetAppCommandLineArguments: [],
            uiTargetAppMainThreadCheckerEnabled: false,
            skipTestIdentifiers: [],
            onlyTestIdentifiers: entriesToRun.map { $0.testName.stringValue },
            testingEnvironmentVariables: [:],
            isUITestBundle: false,
            isAppHostedTestBundle: true,
            isXCTRunnerHostedTestBundle: false
        )
    }

    private func xcTestRunForUiTesting(
        resolvableXcTestBundle: ResolvableResourceLocation
    ) throws -> XcTestRun {
        guard let representableAppBundle = buildArtifacts.appBundle else {
            throw RunnerError.noAppBundleDefinedForUiOrApplicationTesting
        }
        guard let representableRunnerBundle = buildArtifacts.runner else {
            throw RunnerError.noRunnerAppDefinedForUiTesting
        }
        
        let uiTargetAppPath = try resourceLocationResolver.resolvable(resourceLocation: representableAppBundle.resourceLocation).resolve().directlyAccessibleResourcePath()
        let hostAppPath = try resourceLocationResolver.resolvable(resourceLocation: representableRunnerBundle.resourceLocation).resolve().directlyAccessibleResourcePath()

        let dependentProductPaths: [String] = try buildArtifacts.additionalApplicationBundles.map {
            try resourceLocationResolver.resolvable(resourceLocation: $0.resourceLocation).resolve().directlyAccessibleResourcePath()
        } + [uiTargetAppPath]

        return XcTestRun(
            testTargetName: "StubTargetName",
            bundleIdentifiersForCrashReportEmphasis: [],
            dependentProductPaths: dependentProductPaths,
            testBundlePath: try resolvableXcTestBundle.resolve().directlyAccessibleResourcePath(),
            testHostPath: hostAppPath,
            testHostBundleIdentifier: "StubBundleId",
            uiTargetAppPath: uiTargetAppPath,
            environmentVariables: [:],
            commandLineArguments: [],
            uiTargetAppEnvironmentVariables: [:],
            uiTargetAppCommandLineArguments: [],
            uiTargetAppMainThreadCheckerEnabled: false,
            skipTestIdentifiers: [],
            onlyTestIdentifiers: entriesToRun.map { $0.testName.stringValue },
            testingEnvironmentVariables: [
                "DYLD_FRAMEWORK_PATH": "__PLATFORMS__/iPhoneOS.platform/Developer/Library/Frameworks",
                "DYLD_LIBRARY_PATH": "__PLATFORMS__/iPhoneOS.platform/Developer/Library/Frameworks"
            ],
            isUITestBundle: true,
            isAppHostedTestBundle: false,
            isXCTRunnerHostedTestBundle: true
        )
    }
}
