import Deployer
import Foundation
import LaunchdUtils
import QueueModels
import SSHDeployer
import SocketModels

public final class RemoteWorkerLaunchdPlist {

    private let deploymentDestination: DeploymentDestination
    private let emceeVersion: Version
    private let executableDeployableItem: DeployableItem
    private let queueAddress: SocketAddress

    public init(
        deploymentDestination: DeploymentDestination,
        emceeVersion: Version,
        executableDeployableItem: DeployableItem,
        queueAddress: SocketAddress
    ) {
        self.deploymentDestination = deploymentDestination
        self.emceeVersion = emceeVersion
        self.executableDeployableItem = executableDeployableItem
        self.queueAddress = queueAddress
    }
    
    public func plistData() throws -> Data {
        let containerPath = SSHDeployer.remoteContainerPath(
            forDeployable: executableDeployableItem,
            destination: deploymentDestination,
            deploymentId: emceeVersion.value
        )
        let emceeDeployableBinaryFile = try DeployableItemSingleFileExtractor(deployableItem: executableDeployableItem).singleDeployableFile()
        let workerBinaryRemotePath = SSHDeployer.remotePath(
            deployable: executableDeployableItem,
            file: emceeDeployableBinaryFile,
            destination: deploymentDestination,
            deploymentId: emceeVersion.value
        )
        let jobLabel = "ru.avito.emcee.worker.\(emceeVersion.value.removingWhitespaces())"
        let launchdPlist = LaunchdPlist(
            job: LaunchdJob(
                label: jobLabel,
                username: nil,
                groupname: nil,
                programArguments: [
                    workerBinaryRemotePath.pathString, "distWork",
                    "--emcee-version", emceeVersion.value,
                    "--queue-server", queueAddress.asString,
                    "--worker-id", deploymentDestination.workerId.value
                ],
                environmentVariables: [:],
                workingDirectory: containerPath.pathString,
                runAtLoad: true,
                disabled: true,
                standardOutPath: containerPath.appending(component: "stdout.log").pathString,
                standardErrorPath: containerPath.appending(component: "stderr.log").pathString,
                sockets: [:],
                inetdCompatibility: .disabled,
                sessionType: .background
            )
        )
        return try launchdPlist.createPlistData()
    }
}
