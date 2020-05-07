import BuildArtifacts
import Foundation
import Logging
import Models
import PathLib
import ProcessController
import ResourceLocation
import ResourceLocationResolver
import Runner
import TemporaryStuff

public final class XcTestRunFileArgument: SubprocessArgument {
    private let buildArtifacts: BuildArtifacts
    private let entriesToRun: [TestEntry]
    private let resourceLocationResolver: ResourceLocationResolver
    private let temporaryFolder: TemporaryFolder
    private let testContext: TestContext
    private let testType: TestType

    public init(
        buildArtifacts: BuildArtifacts,
        entriesToRun: [TestEntry],
        resourceLocationResolver: ResourceLocationResolver,
        temporaryFolder: TemporaryFolder,
        testContext: TestContext,
        testType: TestType
    ) {
        self.buildArtifacts = buildArtifacts
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
                resolvableXcTestBundle: resolvableXcTestBundle
            )
        case .appTest:
            return try xcTestRunForApplicationTesting(
                resolvableXcTestBundle: resolvableXcTestBundle
            )
        }
    }

    private func xcTestRunForLogicTesting(
        resolvableXcTestBundle: ResolvableResourceLocation
    ) throws -> XcTestRun {
        let testBundlePath = try resolvableXcTestBundle.resolve().directlyAccessibleResourcePath()
        let testHostPath = "__PLATFORMS__/iPhoneSimulator.platform/Developer/Library/Xcode/Agents/xctest"
        
        let xctestSpecificEnvironment = [
            "DYLD_INSERT_LIBRARIES": "__PLATFORMS__/iPhoneSimulator.platform/Developer/usr/lib/libXCTestBundleInject.dylib",
            "XCInjectBundleInto": testHostPath,
        ]
        let testTargetProductModuleName = try self.testTargetProductModuleName(
            xcTestBundlePath: testBundlePath
        )
        
        return XcTestRun(
            testTargetName: testTargetProductModuleName,
            bundleIdentifiersForCrashReportEmphasis: [],
            dependentProductPaths: [
                testBundlePath,
            ],
            testBundlePath: testBundlePath,
            testHostPath: testHostPath,
            testHostBundleIdentifier: "com.apple.dt.xctest.tool",
            uiTargetAppPath: nil,
            environmentVariables: testContext.environment,
            commandLineArguments: [],
            uiTargetAppEnvironmentVariables: testContext.environment,
            uiTargetAppCommandLineArguments: [],
            uiTargetAppMainThreadCheckerEnabled: false,
            skipTestIdentifiers: [],
            onlyTestIdentifiers: entriesToRun.map { $0.testName.stringValue },
            testingEnvironmentVariables: xctestSpecificEnvironment.byMergingWith(testContext.environment),
            isUITestBundle: false,
            isAppHostedTestBundle: false,
            isXCTRunnerHostedTestBundle: false,
            testTargetProductModuleName: testTargetProductModuleName
        )
    }

    private func xcTestRunForApplicationTesting(
        resolvableXcTestBundle: ResolvableResourceLocation
    ) throws -> XcTestRun {
        guard let representableAppBundle = buildArtifacts.appBundle else {
            throw RunnerError.noAppBundleDefinedForUiOrApplicationTesting
        }
        let hostAppPath = try resourceLocationResolver.resolvable(resourceLocation: representableAppBundle.resourceLocation).resolve().directlyAccessibleResourcePath()
        let testBundlePath = try resolvableXcTestBundle.resolve().directlyAccessibleResourcePath()
        let testTargetProductModuleName = try self.testTargetProductModuleName(
            xcTestBundlePath: testBundlePath
        )
        
        return XcTestRun(
            testTargetName: testTargetProductModuleName,
            bundleIdentifiersForCrashReportEmphasis: [],
            dependentProductPaths: [
                hostAppPath,
                testBundlePath,
            ],
            testBundlePath: testBundlePath,
            testHostPath: hostAppPath,
            testHostBundleIdentifier: "StubBundleId",
            uiTargetAppPath: nil,
            environmentVariables: testContext.environment,
            commandLineArguments: [],
            uiTargetAppEnvironmentVariables: testContext.environment,
            uiTargetAppCommandLineArguments: [],
            uiTargetAppMainThreadCheckerEnabled: false,
            skipTestIdentifiers: [],
            onlyTestIdentifiers: entriesToRun.map { $0.testName.stringValue },
            testingEnvironmentVariables: [:],
            isUITestBundle: false,
            isAppHostedTestBundle: true,
            isXCTRunnerHostedTestBundle: false,
            testTargetProductModuleName: testTargetProductModuleName
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
        let testBundlePath = try resolvableXcTestBundle.resolve().directlyAccessibleResourcePath()
        let additionalApplicationBundlePaths: [String] = try buildArtifacts.additionalApplicationBundles.map {
            try resourceLocationResolver.resolvable(resourceLocation: $0.resourceLocation).resolve().directlyAccessibleResourcePath()
        }
        let testTargetProductModuleName = try self.testTargetProductModuleName(
            xcTestBundlePath: testBundlePath
        )

        return XcTestRun(
            testTargetName: testTargetProductModuleName,
            bundleIdentifiersForCrashReportEmphasis: [],
            dependentProductPaths: [uiTargetAppPath, testBundlePath, hostAppPath] + additionalApplicationBundlePaths,
            testBundlePath: testBundlePath,
            testHostPath: hostAppPath,
            testHostBundleIdentifier: "StubBundleId",
            uiTargetAppPath: uiTargetAppPath,
            environmentVariables: testContext.environment,
            commandLineArguments: [],
            uiTargetAppEnvironmentVariables: testContext.environment,
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
            isXCTRunnerHostedTestBundle: true,
            testTargetProductModuleName: testTargetProductModuleName
        )
    }
    
    private func testTargetProductModuleName(
        xcTestBundlePath: String
    ) throws -> String {
        let pathToBundle = AbsolutePath(xcTestBundlePath)
        let plistPath = pathToBundle.appending(component: "Info.plist")
        let plistContents = try PropertyListSerialization.propertyList(
            from: Data(contentsOf: plistPath.fileUrl, options: .mappedIfSafe),
            options: [],
            format: nil
        )
        guard let plistDict = plistContents as? NSDictionary else {
            throw InfoPlistError.failedToReadPlistContents(path: plistPath, contents: plistContents)
        }
        guard let bundleName = plistDict["CFBundleName"] as? String else {
            throw InfoPlistError.noValueCFBundleName(path: plistPath)
        }
        return suitableModuleName(name: bundleName)
    }
    
    private func suitableModuleName(name: String) -> String {
        return name
            .replacingOccurrences(of: ".", with: "_")
            .replacingOccurrences(of: "-", with: "_")
    }
}
