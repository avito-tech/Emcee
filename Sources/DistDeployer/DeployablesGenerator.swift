import Deployer
import Extensions
import Foundation
import Models
import PathLib
import Version

final class DeployablesGenerator {
    private let emceeVersionProvider: VersionProvider
    private let remoteEmceeBinaryName: String

    public init(emceeVersionProvider: VersionProvider, remoteEmceeBinaryName: String) {
        self.emceeVersionProvider = emceeVersionProvider
        self.remoteEmceeBinaryName = remoteEmceeBinaryName
    }
    
    public func deployables() throws -> [DeployableItem] {
        return [try runnerTool()]
    }
    
    public func runnerTool() throws -> DeployableTool {
        return DeployableTool(
            name: "emceeBinary",
            files: [
                DeployableFile(
                    source: AbsolutePath(ProcessInfo.processInfo.executablePath),
                    destination: RelativePath(remoteEmceeBinaryName + "_" + (try emceeVersionProvider.version().value))
                )
            ]
        )
    }
}
