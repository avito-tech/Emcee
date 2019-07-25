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
}
