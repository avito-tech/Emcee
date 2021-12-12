import FileSystem
import Foundation
import EmceeLogging
import PathLib
import Tmp
import UniqueIdentifierGenerator
import Zip

/** Basic class that defines a logic for deploying a number of DeployableItems. */
open class Deployer {
    public let deploymentId: String
    public let deployables: [DeployableItem]
    public let deployableCommands: [DeployableCommand]
    public let destination: DeploymentDestination
    private let fileSystem: FileSystem
    private let logger: ContextualLogger
    private let temporaryFolder: TemporaryFolder
    private let uniqueIdentifierGenerator: UniqueIdentifierGenerator
    private let zipCompressor: ZipCompressor

    public init(
        deploymentId: String,
        deployables: [DeployableItem],
        deployableCommands: [DeployableCommand],
        destination: DeploymentDestination,
        fileSystem: FileSystem,
        logger: ContextualLogger,
        temporaryFolder: TemporaryFolder,
        uniqueIdentifierGenerator: UniqueIdentifierGenerator,
        zipCompressor: ZipCompressor
    ) throws {
        self.deploymentId = deploymentId
        self.deployables = deployables
        self.deployableCommands = deployableCommands
        self.destination = destination
        self.fileSystem = fileSystem
        self.logger = logger
        self.temporaryFolder = temporaryFolder
        self.uniqueIdentifierGenerator = uniqueIdentifierGenerator
        self.zipCompressor = zipCompressor
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
        let syncQueue = DispatchQueue(label: "Deployer.syncQueue")
        var deployablesFailedToPrepare = [DeployableItem]()
        var pathToDeployable = [AbsolutePath: DeployableItem]()
        let packager = Packager(
            fileSystem: fileSystem,
            zipCompressor: zipCompressor
        )
        
        let queue = DispatchQueue(
            label: "Deployer.queue",
            qos: .default,
            attributes: .concurrent,
            autoreleaseFrequency: .workItem,
            target: DispatchQueue.global()
        )
        let group = DispatchGroup()
        for deployable in deployables {
            group.enter()
            queue.async {
                do {
                    self.logger.trace("Preparing deployable '\(deployable.name)'...")
                    let path = try packager.preparePackage(
                        deployable: deployable,
                        packageFolder: try self.temporaryFolder.createDirectory(components: [self.uniqueIdentifierGenerator.generate()])
                    )
                    self.logger.trace("'\(deployable.name)' package path: \(path)")
                    syncQueue.sync { pathToDeployable[path] = deployable }
                } catch {
                    self.logger.error("Failed to prepare deployable \(deployable.name): \(error)")
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
