import AppleTools
import BuildArtifacts
import DeveloperDirLocator
import DeveloperDirModels
import Foundation
import Logging
import PathLib
import ProcessController
import ResourceLocationResolver
import SimulatorPoolModels
import TemporaryStuff
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
    private let resourceLocationResolver: ResourceLocationResolver
    private let processControllerProvider: ProcessControllerProvider
    private let tempFolder: TemporaryFolder
    private let uniqueIdentifierGenerator: UniqueIdentifierGenerator
    
    init(
        appBundleLocation: AppBundleLocation,
        developerDirLocator: DeveloperDirLocator,
        resourceLocationResolver: ResourceLocationResolver,
        processControllerProvider: ProcessControllerProvider,
        tempFolder: TemporaryFolder,
        uniqueIdentifierGenerator: UniqueIdentifierGenerator
    ) {
        self.appBundleLocation = appBundleLocation
        self.developerDirLocator = developerDirLocator
        self.resourceLocationResolver = resourceLocationResolver
        self.processControllerProvider = processControllerProvider
        self.tempFolder = tempFolder
        self.uniqueIdentifierGenerator = uniqueIdentifierGenerator
    }
    
    func discoverTestEntries(
        configuration: TestDiscoveryConfiguration
    ) throws -> [DiscoveredTestEntry] {
        let runtimeEntriesJSONPath = tempFolder.pathWith(components: [uniqueIdentifierGenerator.generate()])
        Logger.debug("Will dump tests from executable into file: \(runtimeEntriesJSONPath)")
        
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
                environment: [
                    "SIMULATOR_ROOT": latestRuntimeRoot,
                    "DYLD_ROOT_PATH": latestRuntimeRoot,
                    "SIMULATOR_SHARED_RESOURCES_DIRECTORY": tempFolder.pathByCreatingDirectories(
                        components: [uniqueIdentifierGenerator.generate()]
                    ).pathString,
                    "EMCEE_RUNTIME_TESTS_EXPORT_PATH": runtimeEntriesJSONPath.pathString,
                    "EMCEE_XCTEST_BUNDLE_PATH": loadableBundlePath.pathString,
                ].merging(
                    configuration.testExecutionBehavior.environment,
                    uniquingKeysWith: { (_, new) in new }
                )
            )
        )
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
                environment: try developerDirLocator.suitableEnvironment(forDeveloperDir: developerDir)
            )
        )
        try controller.startAndWaitForSuccessfulTermination()
        
        let runtimes = try JSONDecoder().decode(
            SimulatorRuntimes.self,
            from: Data(contentsOf: controller.subprocess.standardStreamsCaptureConfig.stdoutOutputPath().fileUrl)
        )
        
        guard let runtime = runtimes.runtimes.first(
            where: { $0.name == "iOS \(testDestination.runtime)" }
        ) else {
            throw Errors.runtimeRootNotFound(testDestination: testDestination)
        }
        
        return runtime.bundlePath.appending(component: "Contents/Resources/RuntimeRoot").pathString
    }
}
