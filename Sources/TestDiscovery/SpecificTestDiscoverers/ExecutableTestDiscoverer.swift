import AppleTools
import BuildArtifacts
import DeveloperDirLocator
import DeveloperDirModels
import Foundation
import EmceeLogging
import PathLib
import ProcessController
import ResourceLocationResolver
import SimulatorPoolModels
import Tmp
import UniqueIdentifierGenerator

final class ExecutableTestDiscoverer: SpecificTestDiscoverer {
    
    enum Errors: Error, CustomStringConvertible {
        case bundleExecutableNotFound(path: AbsolutePath)
        case runtimeRootNotFound(testDestination: TestDestination)
        
        var description: String {
            switch self {
            case .bundleExecutableNotFound(let path):
                return "Bundle executable not found in \(path)"
            case .runtimeRootNotFound(let testDestination):
                return "Runtime root not found for \(testDestination)"
            }
        }
    }
    
    private let appBundleLocation: AppBundleLocation
    private let developerDirLocator: DeveloperDirLocator
    private let logger: ContextualLogger
    private let resourceLocationResolver: ResourceLocationResolver
    private let processControllerProvider: ProcessControllerProvider
    private let tempFolder: TemporaryFolder
    private let uniqueIdentifierGenerator: UniqueIdentifierGenerator
    
    init(
        appBundleLocation: AppBundleLocation,
        developerDirLocator: DeveloperDirLocator,
        logger: ContextualLogger,
        resourceLocationResolver: ResourceLocationResolver,
        processControllerProvider: ProcessControllerProvider,
        tempFolder: TemporaryFolder,
        uniqueIdentifierGenerator: UniqueIdentifierGenerator
    ) {
        self.appBundleLocation = appBundleLocation
        self.developerDirLocator = developerDirLocator
        self.logger = logger.forType(Self.self)
        self.resourceLocationResolver = resourceLocationResolver
        self.processControllerProvider = processControllerProvider
        self.tempFolder = tempFolder
        self.uniqueIdentifierGenerator = uniqueIdentifierGenerator
    }
    
    func discoverTestEntries(
        configuration: TestDiscoveryConfiguration
    ) throws -> [DiscoveredTestEntry] {
        let runtimeEntriesJSONPath = tempFolder.pathWith(components: [uniqueIdentifierGenerator.generate()])
        logger.debug("Will dump tests from \(configuration.xcTestBundleLocation) into file: \(runtimeEntriesJSONPath)")
        
        let latestRuntimeRoot = try findRuntimeRoot(
            testDestination: configuration.testDestination,
            developerDir: configuration.developerDir
        )
        
        let appBundlePath = try resourceLocationResolver.resolvable(
            resourceLocation: appBundleLocation.resourceLocation
        ).resolve().directlyAccessibleResourcePath()
        
        guard let executablePath = Bundle(path: appBundlePath.pathString)?.executablePath else {
            throw Errors.bundleExecutableNotFound(path: appBundlePath)
        }
        
        let loadableBundlePath = try resourceLocationResolver.resolvable(
            resourceLocation: configuration.xcTestBundleLocation.resourceLocation
        ).resolve().directlyAccessibleResourcePath()
        
        let controller = try processControllerProvider.createProcessController(
            subprocess: Subprocess(
                arguments: [
                    executablePath
                ],
                environment: Environment([
                    "SIMULATOR_ROOT": latestRuntimeRoot,
                    "DYLD_ROOT_PATH": latestRuntimeRoot,
                    "SIMULATOR_SHARED_RESOURCES_DIRECTORY": tempFolder.pathByCreatingDirectories(
                        components: [uniqueIdentifierGenerator.generate()]
                    ).pathString,
                    "EMCEE_RUNTIME_TESTS_EXPORT_PATH": runtimeEntriesJSONPath.pathString,
                    "EMCEE_XCTEST_BUNDLE_PATH": loadableBundlePath.pathString,
                ]).merge(with: configuration.testExecutionBehavior.environment)
            )
        )
        
        controller.onStdout { [logger] sender, data, _ in
            logger.skippingStdOutput.debugFromData(data, subprocessPidInfo: sender.subprocessInfo.pidInfo)
        }
        
        try controller.startAndWaitForSuccessfulTermination()
        
        return try JSONDecoder().decode(
            [DiscoveredTestEntry].self,
            from: Data(contentsOf: runtimeEntriesJSONPath.fileUrl)
        )
    }
    
    private func findRuntimeRoot(
        testDestination: TestDestination,
        developerDir: DeveloperDir
    ) throws -> String {
        let controller = try processControllerProvider.createProcessController(
            subprocess: Subprocess(
                arguments: [
                    "/usr/bin/xcrun",
                    "simctl", "list", "-j", "runtimes"
                ],
                environment: Environment(
                    try developerDirLocator.suitableEnvironment(forDeveloperDir: developerDir)
                )
            )
        )
        
        var capturedData = Data()
        controller.onStdout { _, data, _ in capturedData.append(data) }
        
        controller.onStdout { [logger] sender, data, _ in
            logger.skippingStdOutput.debugFromData(data, subprocessPidInfo: sender.subprocessInfo.pidInfo)
        }
        
        try controller.startAndWaitForSuccessfulTermination()
        
        let runtimes = try JSONDecoder().decode(SimulatorRuntimes.self, from: capturedData)
        
        guard let runtime = runtimes.runtimes.first(
            where: { $0.name == "iOS \(testDestination.runtime)" }
        ) else {
            throw Errors.runtimeRootNotFound(testDestination: testDestination)
        }
        
        return runtime.bundlePath.appending(component: "Contents/Resources/RuntimeRoot").pathString
    }
}
