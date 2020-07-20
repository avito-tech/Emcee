import Deployer
import Extensions
import Foundation
import PathLib
import QueueModels

final class DeployablesGenerator {
    private let emceeVersion: Version
    private let remoteEmceeBinaryName: String

    public init(emceeVersion: Version, remoteEmceeBinaryName: String) {
        self.emceeVersion = emceeVersion
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
                    destination: RelativePath(remoteEmceeBinaryName + "_" + emceeVersion.value)
                )
            ]
        )
    }
}
