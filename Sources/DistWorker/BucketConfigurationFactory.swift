import EventBus
import Extensions
import Foundation
import Logging
import Models
import PathLib
import Runner
import Scheduler
import SimulatorPool
import TemporaryStuff
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
    
    private var containerPath: AbsolutePath {
        /*
         The expected structure is:
         /remote_path/some_run_id/emceeBinary/BinaryName   <-- executable path
         /remote_path/some_run_id/plugin/SomePluginName/SomePluginName.emceeplugin
         and so on.

         The containerPath is resolved into:
         /remote_path/some_run_id/
         */
        return AbsolutePath(ProcessInfo.processInfo.executablePath)
            .removingLastComponent
            .removingLastComponent
    }
    
    func createTemporaryStuff() throws -> TemporaryFolder {
        /*
         Temp folder is next to the binary:
         /remote_path/some_run_id/emceeBinary/tempFolder/someUUID
         */
        let path = packagePath(containerPath, .emceeBinary).appending(component: "tempFolder")
        return try TemporaryFolder(containerPath: path, deleteOnDealloc: true)
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
            path: packagePath(containerPath, .plugin).pathString,
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
    
    private func packagePath(_ containerPath: AbsolutePath, _ package: PackageName) -> AbsolutePath {
        return containerPath.appending(component: package.rawValue)
    }
    
    private func fileInPackage(_ containerPath: AbsolutePath, _ package: PackageName) throws -> AbsolutePath {
        let result = packagePath(containerPath, package)
        return result.appending(component: try PackageName.targetFileName(package))
    }
    
    private func fileInPackageIfExists(_ containerPath: AbsolutePath, _ package: PackageName) throws -> AbsolutePath? {
        let path = try fileInPackage(containerPath, package)
        return FileManager.default.fileExists(atPath: path.pathString) ? path : nil
    }
}
