import Basic
import EventBus
import Extensions
import Foundation
import Logging
import Models
import Runner
import Scheduler
import SimulatorPool
import TempFolder
import ResourceLocationResolver

/**
 * This class takes a bucket, a worker configuration and walks the surroundings in order to create a configuration
 * suitable for running tests locally on worker's behalf.
 */
final class BucketConfigurationFactory {
    private let resourceLocationResolver: ResourceLocationResolver
    init(resourceLocationResolver: ResourceLocationResolver) {
        self.resourceLocationResolver = resourceLocationResolver
    }
    
    private var containerPath: String {
        /*
         The expected structure is:
         /remote_path/some_run_id/emceeBinary/BinaryName   <-- executable path
         /remote_path/some_run_id/plugin/SomePluginName/SomePluginName.emceeplugin
         and so on.

         The containerPath is resolved into:
         /remote_path/some_run_id/
         */
        return ProcessInfo.processInfo.executablePath.deletingLastPathComponent.deletingLastPathComponent
    }
    
    func createTempFolder() throws -> TempFolder {
        /*
         Temp folder is next to the binary:
         /remote_path/some_run_id/emceeBinary/tempFolder/someUUID
         */
        let path = try AbsolutePath(validating: packagePath(containerPath, .emceeBinary))
            .appending(component: "tempFolder")
        return try TempFolder(path: path, cleanUpAutomatically: true)
    }
    
    func createConfiguration(
        workerConfiguration: WorkerConfiguration,
        schedulerDataSource: SchedulerDataSource,
        onDemandSimulatorPool: OnDemandSimulatorPool<DefaultSimulatorController>)
        -> SchedulerConfiguration
    {
        return SchedulerConfiguration(
            testRunExecutionBehavior: workerConfiguration.testRunExecutionBehavior,
            testTimeoutConfiguration: workerConfiguration.testTimeoutConfiguration,
            schedulerDataSource: schedulerDataSource,
            onDemandSimulatorPool: onDemandSimulatorPool
        )
    }
    
    public var pluginLocations: [PluginLocation] {
        let plugins = FileManager.default.findFiles(
            path: packagePath(containerPath, .plugin),
            defaultValue: [])
            .map { path -> String in
                let path = path.appending(pathComponent: "\(path.lastPathComponent).emceeplugin")
                Logger.verboseDebug("Found plugin candidate: \(path)")
                return path
            }
            .filter { path -> Bool in
                var isDir: ObjCBool = false
                let result = FileManager.default.fileExists(atPath: path, isDirectory: &isDir)
                Logger.verboseDebug("Plugin candidate at \(path) exists: \(result), isDir: \(isDir)")
                return result && isDir.boolValue == true
        }
        return plugins.map { PluginLocation(.localFilePath($0)) }
    }
    
    private func packagePath(_ containerPath: String, _ package: PackageName) -> String {
        return containerPath.appending(pathComponent: package.rawValue)
    }
    
    private func fileInPackage(_ containerPath: String, _ package: PackageName) throws -> String {
        let result = packagePath(containerPath, package)
        return result.appending(pathComponent: try PackageName.targetFileName(package))
    }
    
    private func fileInPackageIfExists(_ containerPath: String, _ package: PackageName) throws -> String? {
        let path = try fileInPackage(containerPath, package)
        return FileManager.default.fileExists(atPath: path) ? path : nil
    }
}
