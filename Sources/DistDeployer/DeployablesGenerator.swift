import Deployer
import Extensions
import Foundation
import Models
import PathLib
import Version

final class DeployablesGenerator {
    private let emceeVersionProvider: VersionProvider
    private let pluginLocations: [PluginLocation]
    private let remoteEmceeBinaryName: String

    public init(emceeVersionProvider: VersionProvider, pluginLocations: [PluginLocation], remoteEmceeBinaryName: String) {
        self.emceeVersionProvider = emceeVersionProvider
        self.pluginLocations = pluginLocations
        self.remoteEmceeBinaryName = remoteEmceeBinaryName
    }
    
    public func deployables() throws -> [PackageName: [DeployableItem]] {
        var deployables = [PackageName: [DeployableItem]]()
        deployables[.emceeBinary] = [try runnerTool()]
        deployables[.plugin] = try pluginDeployables()
        return deployables
    }
    
    public func runnerTool() throws -> DeployableTool {
        return DeployableTool(
            name: PackageName.emceeBinary.rawValue,
            files: [
                DeployableFile(
                    source: AbsolutePath(ProcessInfo.processInfo.executablePath),
                    destination: RelativePath(remoteEmceeBinaryName + "_" + (try emceeVersionProvider.version().value))
                )
            ]
        )
    }
    
    func pluginDeployables() throws -> [DeployableItem] {
        return try pluginLocations.flatMap { location -> [DeployableItem] in
            switch location.resourceLocation {
            case .localFilePath(let path):
                let bundlePath = AbsolutePath(path)
                let name = PackageName.plugin.rawValue.appending(
                    pathComponent: path.lastPathComponent.deletingPathExtension)
                return [try DeployableBundle(name: name, bundlePath: bundlePath)]
            case .remoteUrl:
                // in this case we rely that queue server should provide these URLs via REST API
                return []
            }
        }
    }
}
