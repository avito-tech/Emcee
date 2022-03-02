import AppleTools
import BuildArtifacts
import DeveloperDirLocator
import DeveloperDirModels
import Foundation
import EmceeLogging
import PathLib
import PluginManager
import ProcessController
import ResourceLocationResolver
import Runner
import SimulatorPool
import SimulatorPoolModels
import SynchronousWaiter

public final class ParseFunctionSymbolsTestDiscoverer: SpecificTestDiscoverer {
    private let developerDirLocator: DeveloperDirLocator
    private let logger: ContextualLogger
    private let processControllerProvider: ProcessControllerProvider
    private let resourceLocationResolver: ResourceLocationResolver

    public init(
        developerDirLocator: DeveloperDirLocator,
        logger: ContextualLogger,
        processControllerProvider: ProcessControllerProvider,
        resourceLocationResolver: ResourceLocationResolver
    ) {
        self.developerDirLocator = developerDirLocator
        self.logger = logger
        self.processControllerProvider = processControllerProvider
        self.resourceLocationResolver = resourceLocationResolver
    }
    
    public func discoverTestEntries(
        configuration: AppleTestDiscoveryConfiguration
    ) throws -> [DiscoveredTestEntry] {
        try discoverTestEntries(
            developerDir: configuration.testConfiguration.developerDir,
            xcTestBundleLocation: configuration.testConfiguration.buildArtifacts.xcTestBundle.location
        )
    }
    
    public func discoverTestEntries(
        developerDir: DeveloperDir,
        xcTestBundleLocation: TestBundleLocation
    ) throws -> [DiscoveredTestEntry] {
        let nmProcess = try processControllerProvider.createProcessController(
            subprocess: Subprocess(
                arguments: [
                    "/usr/bin/nm", "-j", "-U",
                    try testBinaryPath(xcTestBundleLocation: xcTestBundleLocation)
                ]
            )
        )
        var nmOutputData = Data()
        nmProcess.onStdout { _, data, _ in nmOutputData.append(data) }
        try nmProcess.startAndWaitForSuccessfulTermination()
        
        return try convert(
            developerDir: developerDir,
            nmOutputData: nmOutputData,
            logger: logger
        )
    }
    
    private func testBinaryPath(
        xcTestBundleLocation: TestBundleLocation
    ) throws -> AbsolutePath {
        let resourcePath = try resourceLocationResolver.resolvable(
            resourceLocation: xcTestBundleLocation.resourceLocation
        ).resolve().directlyAccessibleResourcePath()
        
        let absolutePlistPath = resourcePath.appending("Info.plist")
        let plistContents = try PropertyListSerialization.propertyList(
            from: try Data(contentsOf: absolutePlistPath.fileUrl),
            options: [],
            format: nil
        )
        guard let plistDict = plistContents as? NSDictionary else {
            throw InfoPlistError.failedToReadPlistContents(path: absolutePlistPath, contents: plistContents)
        }
        guard let executableName = plistDict["CFBundleExecutable"] as? String else {
            throw InfoPlistError.noValueCFBundleExecutable(path: absolutePlistPath)
        }
        return resourcePath.appending(executableName)
    }
    
    private func convert(
        developerDir: DeveloperDir,
        nmOutputData: Data,
        logger: ContextualLogger
    ) throws -> [DiscoveredTestEntry] {
        guard let string = String(data: nmOutputData, encoding: .utf8) else {
            logger.error("Failed to get contents of nm output from \(nmOutputData.count) bytes")
            return []
        }
        
        let demangler = try LibSwiftDemangler(
            libswiftDemanglePath: developerDirLocator.path(developerDir: developerDir).appending(
                relativePath: RelativePath("Toolchains/XcodeDefault.xctoolchain/usr/lib/libswiftDemangle.dylib")
            )
        )
        
        return try string.split(separator: "\n").compactMap {
            try demangleAndCompactMap(string: String($0), demangler: demangler, logger: logger)
        }
    }
    
    private func demangleAndCompactMap(
        string: String,
        demangler: Demangler,
        logger: ContextualLogger
    ) throws -> DiscoveredTestEntry? {
        guard let demangledString = try demangler.demangle(string: string, bufferSize: 10240) else {
            return nil
        }
        
        // @objc ModuleName.ClassName.testMethodName() -> ()
        let expectedPrefix = "@objc "
        let expectedSuffixes = ["() -> ()", "() throws -> ()"]
        
        guard demangledString.hasPrefix(expectedPrefix) else {
            return nil
        }
        
        let matchingSuffixes = expectedSuffixes.compactMap({ demangledString.hasSuffix($0) ? $0 : nil })
        guard !matchingSuffixes.isEmpty, let matchingSuffix = matchingSuffixes.last else {
            return nil
        }
        
        guard demangledString.split(separator: ".", omittingEmptySubsequences: false).count == 3 else {
            return nil
        }
        
        var moduledTestName = demangledString
        moduledTestName = String(moduledTestName.dropFirst(expectedPrefix.count))
        moduledTestName = String(moduledTestName.dropLast(matchingSuffix.count))
        
        guard !moduledTestName.contains(" ") else {
            return nil
        }
        
        let components = try TestNameParser.components(moduledTestName: moduledTestName)
        
        guard components.methodName.hasPrefix("test") else {
            return nil
        }
        
        let discoveredTestEntry = DiscoveredTestEntry(
            className: components.className,
            path: "",
            testMethods: [components.methodName], caseId: nil,
            tags: []
        )
        return discoveredTestEntry
    }
}
