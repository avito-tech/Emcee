import Foundation
import EmceeLogging
import PathLib
import ProcessController
import Tmp
import UniqueIdentifierGenerator

/** Basic class that defines a logic for deploying a number of DeployableItems. */
open class Deployer {
    public let deploymentId: String
    public let deployables: [DeployableItem]
    public let deployableCommands: [DeployableCommand]
    public let destination: DeploymentDestination
    private let processControllerProvider: ProcessControllerProvider
    private let temporaryFolder: TemporaryFolder
    private let uniqueIdentifierGenerator: UniqueIdentifierGenerator

    public init(
        deploymentId: String,
        deployables: [DeployableItem],
        deployableCommands: [DeployableCommand],
        destination: DeploymentDestination,
        processControllerProvider: ProcessControllerProvider,
        temporaryFolder: TemporaryFolder,
        uniqueIdentifierGenerator: UniqueIdentifierGenerator
    ) throws {
        self.deploymentId = deploymentId
        self.deployables = deployables
        self.deployableCommands = deployableCommands
        self.destination = destination
        self.processControllerProvider = processControllerProvider
        self.temporaryFolder = temporaryFolder
        self.uniqueIdentifierGenerator = uniqueIdentifierGenerator
    }
    
    /** Deploys all the deployable items and invokes deployment commands. */
    public func deploy() throws {
        try deployToDestination(
            pathToDeployable: try prepareDeployables()
        )
    }
    
    /**
     * Packs all the Deployables and returns a map
     * from a URL with a package of the DeployableItem to a corresponding DeployableItem
     */
    private func prepareDeployables() throws -> [AbsolutePath: DeployableItem] {
        let syncQueue = DispatchQueue(label: "ru.avito.Deployer.syncQueue")
        var deployablesFailedToPrepare = [DeployableItem]()
        var pathToDeployable = [AbsolutePath: DeployableItem]()
        let packager = Packager(processControllerProvider: processControllerProvider)
        
        let queue = DispatchQueue(
            label: "ru.avito.Deployer",
            qos: .default,
            attributes: .concurrent,
            autoreleaseFrequency: .workItem,
            target: nil)
        let group = DispatchGroup()
        for deployable in deployables {
            group.enter()
            queue.async {
                do {
                    Logger.debug("Preparing deployable '\(deployable.name)'...")
                    let path = try packager.preparePackage(
                        deployable: deployable,
                        packageFolder: try self.temporaryFolder.pathByCreatingDirectories(components: [self.uniqueIdentifierGenerator.generate()])
                    )
                    Logger.debug("'\(deployable.name)' package path: \(path)")
                    syncQueue.sync { pathToDeployable[path] = deployable }
                } catch {
                    Logger.error("Failed to prepare deployable \(deployable.name): \(error)")
                    syncQueue.sync { deployablesFailedToPrepare.append(deployable) }
                }
                group.leave()
            }
        }
        group.wait()

        if !deployablesFailedToPrepare.isEmpty {
            throw DeploymentError.failedToPrepareDeployable(deployablesFailedToPrepare)
        }
        return pathToDeployable
    }
    
    /**
     * Subclasses should override this to perform their delivery logic.
     * @param   urlToDeployable   A map from local URL of package (zip) to a deployable item it represents.
     */
    open func deployToDestination(
        pathToDeployable: [AbsolutePath: DeployableItem]
    ) throws {
        fatalError("Deployer.deployToDestinations() must be overrided in subclass")
    }
}
