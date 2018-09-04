import Foundation
import Deployer
import Extensions
import Models

public final class DeployablesGenerator {
    let targetAvitoRunnerPath: String
    let auxiliaryPaths: AuxiliaryPaths
    let buildArtifacts: BuildArtifacts
    let environmentFilePath: String
    let targetEnvironmentPath: String
    let simulatorSettings: SimulatorSettings
    let targetSimulatorLocalizationSettingsPath: String
    let targetWatchdogSettingsPath: String

    public init(
        targetAvitoRunnerPath: String,
        auxiliaryPaths: AuxiliaryPaths,
        buildArtifacts: BuildArtifacts,
        environmentFilePath: String,
        targetEnvironmentPath: String,
        simulatorSettings: SimulatorSettings,
        targetSimulatorLocalizationSettingsPath: String,
        targetWatchdogSettingsPath: String)
    {
        self.targetAvitoRunnerPath = targetAvitoRunnerPath
        self.auxiliaryPaths = auxiliaryPaths
        self.buildArtifacts = buildArtifacts
        self.environmentFilePath = environmentFilePath
        self.targetEnvironmentPath = targetEnvironmentPath
        self.simulatorSettings = simulatorSettings
        self.targetSimulatorLocalizationSettingsPath = targetSimulatorLocalizationSettingsPath
        self.targetWatchdogSettingsPath = targetWatchdogSettingsPath
    }
    
    public func deployables() throws -> [PackageName: [DeployableItem]] {
        let addtionalAppDeployables: [DeployableItem] = try buildArtifacts.additionalApplicationBundles.map {
            let url = URL(fileURLWithPath: $0)
            let name = PackageName.additionalApp.rawValue.appending(
                pathComponent: url.lastPathComponent.deletingPathExtension)
            return try DeployableBundle(name: name, bundleUrl: url)
        }
        
        return [
            .avitoRunner: [runnerTool()],
            .fbsimctl: [try toolForBinary(binaryPath: auxiliaryPaths.fbsimctl, toolName: PackageName.fbsimctl.rawValue)],
            .fbxctest: [try toolForBinary(binaryPath: auxiliaryPaths.fbxctest, toolName: PackageName.fbxctest.rawValue)],
            .app: [
                try DeployableBundle(
                    name: PackageName.app.rawValue,
                    bundleUrl: URL(fileURLWithPath: buildArtifacts.appBundle))
            ],
            .additionalApp: addtionalAppDeployables,
            .testRunner: [
                try DeployableBundle(
                    name: PackageName.testRunner.rawValue,
                    bundleUrl: URL(fileURLWithPath: buildArtifacts.runner))],
            .xctestBundle: [
                try DeployableBundle(
                    name: PackageName.xctestBundle.rawValue,
                    bundleUrl: URL(fileURLWithPath: buildArtifacts.xcTestBundle))],
            .environment: [
                DeployableItem(
                    name: PackageName.environment.rawValue,
                    files: [DeployableFile(source: environmentFilePath, destination: targetEnvironmentPath)])],
            .simulatorLocalizationSettings: [
                DeployableItem(
                    name: PackageName.simulatorLocalizationSettings.rawValue,
                    files: [
                        DeployableFile(
                            source: simulatorSettings.simulatorLocalizationSettings,
                            destination: targetSimulatorLocalizationSettingsPath)])],
            .watchdogSettings: [
                DeployableItem(
                    name: PackageName.watchdogSettings.rawValue,
                    files: [
                        DeployableFile(
                            source: simulatorSettings.watchdogSettings,
                            destination: targetWatchdogSettingsPath)])]
        ]
    }
    
    func runnerTool() -> DeployableTool {
        let path = ProcessInfo.processInfo.arguments.elementAtIndex(
            0,
            "First launch arg which always set and points to executable")
        return DeployableTool(
            name: PackageName.avitoRunner.rawValue,
            files: [DeployableFile(source: path, destination: targetAvitoRunnerPath)])
    }
    
    func toolForBinary(binaryPath: String, toolName: String) throws -> DeployableTool {
        let parentDirPath = binaryPath.deletingLastPathComponent
        let bundleName = parentDirPath.lastPathComponent
        let url = URL(fileURLWithPath: parentDirPath)
        let files = try DeployableBundle.filesForBundle(bundleUrl: url)
            .filter { file -> Bool in
                // We remove the bundle directory itself: we do deploy tool with some surrounding files,
                // so we don't deploy its parent folder
                file.source != url.path
            }
            .map { (file: DeployableFile) -> DeployableFile in
                guard let updatedDestination = file.destination.stringWithPathRelativeTo(anchorPath: bundleName) else {
                    throw DeploymentError.failedToRelativizePath(file.destination, anchorPath: bundleName)
                }
                return DeployableFile(source: file.source, destination: updatedDestination)
            }
        return DeployableTool(name: toolName, files: Set(files))
    }
}
