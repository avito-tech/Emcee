import Basic
import EventBus
import Foundation
import Logging
import Models
import Runner
import Scheduler
import SimulatorPool
import TempFolder

/**
 * This class takes a bucket, a worker configuration and walks the surroundings in order to create a configuration
 * suitable for running tests locally on worker's behalf.
 */
final class BucketConfigurationFactory {
    init() {}
    
    private var containerPath: String {
        /*
         The expected structure is:
         /remote_path/some_run_id/avitoRunner/AvitoRunner
         /remote_path/some_run_id/fbxctest/fbxctest
         /remote_path/some_run_id/app/AppUnderTest.app
         /remote_path/some_run_id/additionalApp/OneMoreApp/OneMoreApp.app
         /remote_path/some_run_id/plugin/SomePluginName/SomePluginName.emceeplugin
         and so on.
         */
        let pathToBinary = ProcessInfo.processInfo.arguments[0]
        
        /*
         The containerPath is resolved into:
         /remote_path/some_run_id/
         */
        let containerPath = pathToBinary.deletingLastPathComponent.deletingLastPathComponent
        return containerPath
    }
    
    func createTempFolder() throws -> TempFolder {
        /*
         Temp folder is next to the binary:
         /remote_path/some_run_id/avitoRunner/tempFolder/someUUID
         */
        let path = try AbsolutePath(validating: packagePath(containerPath, .avitoRunner))
            .appending(component: "tempFolder")
        return try TempFolder(path: path, cleanUpAutomatically: true)
    }
    
    func createConfiguration(
        workerConfiguration: WorkerConfiguration,
        schedulerDataSource: SchedulerDataSource,
        onDemandSimulatorPool: OnDemandSimulatorPool<DefaultSimulatorController>)
        throws -> SchedulerConfiguration
    {
        /*
         All paths below are resolved against containerPath.
         */
        let fbxctest = try fileInPackage(containerPath, .fbxctest)
        let fbsimctl = try fileInPackage(containerPath, .fbsimctl)
        let app = try FileManager.default.findFiles(
            path: packagePath(containerPath, .app),
            pathExtension: "app")
            .elementAtIndex(0, "First and single app bundle")
        let additionalApps = FileManager.default.findFiles(
            path: packagePath(containerPath, .additionalApp),
            defaultValue: [])
            .map { path -> String in
                let path = path.appending(pathComponent: "\(path.lastPathComponent).app")
                log("Found additional app candidate: \(path)")
                return path
            }
            .filter { path -> Bool in
                var isDir: ObjCBool = false
                let result = FileManager.default.fileExists(atPath: path, isDirectory: &isDir)
                log("Additional app candidate at \(path) exists: \(result), isDir: \(isDir)")
                return result && isDir.boolValue == true
        }
        let plugins = FileManager.default.findFiles(
            path: packagePath(containerPath, .plugin),
            defaultValue: [])
            .map { path -> String in
                let path = path.appending(pathComponent: "\(path.lastPathComponent).emceeplugin")
                log("Found plugin candidate: \(path)")
                return path
            }
            .filter { path -> Bool in
                var isDir: ObjCBool = false
                let result = FileManager.default.fileExists(atPath: path, isDirectory: &isDir)
                log("Plugin candidate at \(path) exists: \(result), isDir: \(isDir)")
                return result && isDir.boolValue == true
        }
        let runner = try FileManager.default.findFiles(
            path: packagePath(containerPath, .testRunner),
            suffix: "-Runner",
            pathExtension: "app")
            .elementAtIndex(0, "First and single XCTRunner.app")
        let xcTestBundle = try FileManager.default.findFiles(
            path: packagePath(containerPath, .xctestBundle),
            pathExtension: "xctest")
            .elementAtIndex(0, "First and single xctest bundle")
        let simulatorLocalizationSettings = try fileInPackageIfExists(containerPath, .simulatorLocalizationSettings)
        let watchdogSettings = try fileInPackageIfExists(containerPath, .watchdogSettings)
        
        let configuration = SchedulerConfiguration(
            auxiliaryPaths: AuxiliaryPaths(
                fbxctest: ResourceLocation.localFilePath(fbxctest),
                fbsimctl: ResourceLocation.localFilePath(fbsimctl),
                plugins: plugins.map { ResourceLocation.localFilePath($0) }),
            testType: .uiTest,
            buildArtifacts: BuildArtifacts(
                appBundle: app,
                runner: runner,
                xcTestBundle: xcTestBundle,
                additionalApplicationBundles: additionalApps),
            testExecutionBehavior: workerConfiguration.testExecutionBehavior,
            simulatorSettings: SimulatorSettings(
                simulatorLocalizationSettings: simulatorLocalizationSettings,
                watchdogSettings: watchdogSettings),
            testTimeoutConfiguration: workerConfiguration.testTimeoutConfiguration,
            testDiagnosticOutput: TestDiagnosticOutput.nullOutput,
            schedulerDataSource: schedulerDataSource,
            onDemandSimulatorPool: onDemandSimulatorPool)
        return configuration
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
