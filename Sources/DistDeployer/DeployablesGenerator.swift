import Foundation
import Deployer
import Extensions
import Models

final class DeployablesGenerator {
    private let remoteAvitoRunnerPath: String
    private let pluginLocations: [PluginLocation]

    public init(
        remoteAvitoRunnerPath: String,
        pluginLocations: [PluginLocation])
    {
        self.remoteAvitoRunnerPath = remoteAvitoRunnerPath
        self.pluginLocations = pluginLocations
    }
    
    public func deployables() throws -> [PackageName: [DeployableItem]] {
        var deployables = [PackageName: [DeployableItem]]()
        deployables[.avitoRunner] = [runnerTool]
        deployables[.plugin] = try pluginDeployables()
        return deployables
    }
    
    public var runnerTool: DeployableTool {
        return DeployableTool(
            name: PackageName.avitoRunner.rawValue,
            files: [
                DeployableFile(source: ProcessInfo.processInfo.executablePath, destination: remoteAvitoRunnerPath)
            ]
        )
    }
    
    func pluginDeployables() throws -> [DeployableItem] {
        return try pluginLocations.flatMap { location -> [DeployableItem] in
            switch location.resourceLocation {
            case .localFilePath(let path):
                let url = URL(fileURLWithPath: path)
                let name = PackageName.plugin.rawValue.appending(
                    pathComponent: url.lastPathComponent.deletingPathExtension)
                return [try DeployableBundle(name: name, bundleUrl: url)]
            case .remoteUrl:
                // in this case we rely that queue server should provide these URLs via REST API
                return []
            }
        }
    }
}
