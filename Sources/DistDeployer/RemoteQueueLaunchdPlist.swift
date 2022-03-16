import Deployer
import Foundation
import LaunchdUtils
import PathLib
import QueueModels
import SSHDeployer
import Tmp

public final class RemoteQueueLaunchdPlist {
    /// Unique deployment id
    private let deploymentId: String
    /// Emcee binary version
    private let emceeVersion: Version
    /// Hostname which queue should use to set up communications
    private let hostname: String
    /// Path to QueueServerConfiguration JSON at the deployment location
    private let queueServerConfigurationPath: AbsolutePath
    /// Path to the working directory of an Emcee binary at the deployment location
    private let containerPath: AbsolutePath
    /// Path to the Emcee binary at the deployment location
    private let remoteQueueServerBinaryPath: AbsolutePath

    public init(
        deploymentId: String,
        emceeVersion: Version,
        hostname: String,
        queueServerConfigurationPath: AbsolutePath,
        containerPath: AbsolutePath,
        remoteQueueServerBinaryPath: AbsolutePath
    ) {
        self.deploymentId = deploymentId
        self.emceeVersion = emceeVersion
        self.hostname = hostname
        self.queueServerConfigurationPath = queueServerConfigurationPath
        self.containerPath = containerPath
        self.remoteQueueServerBinaryPath = remoteQueueServerBinaryPath
    }
    
    public func plistData() throws -> Data {
        let jobLabel = "ru.avito.emcee.queueServer.\(deploymentId.removingWhitespaces())"
        
        let launchdPlist = LaunchdPlist(
            job: LaunchdJob(
                label: jobLabel,
                username: nil,
                groupname: nil,
                programArguments: [
                    remoteQueueServerBinaryPath.pathString, "startLocalQueueServer",
                    "--emcee-version", emceeVersion.value,
                    "--queue-server-configuration-location", queueServerConfigurationPath.pathString,
                    "--hostname", hostname,
                ],
                environmentVariables: [:],
                workingDirectory: containerPath.pathString,
                runAtLoad: true,
                disabled: true,
                standardOutPath: containerPath.appending("stdout.log").pathString,
                standardErrorPath: containerPath.appending("stderr.log").pathString,
                sockets: [:],
                inetdCompatibility: .disabled,
                sessionType: .background
            )
        )
        return try launchdPlist.createPlistData()
    }
}
