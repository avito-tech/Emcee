import Foundation
import Basic
import Logging

/** Basic class that defines a logic for deploying a number of DeployableItems. */
open class Deployer {
    /**
     * Some unique id.
     * Allows to avoid a conflict when you deploy the same (or similar) deployables.
     * Used as an identifier for a container. */
    public let deploymentId: String
    /** All deployables that must be deployed. */
    public let deployables: [DeployableItem]
    /** Commands that must be invoked after deploy finishes. */
    public let deployableCommands: [DeployableCommand]
    /** All destinations. */
    public let destinations: [DeploymentDestination]
    /** Used for storing temporary files. */
    private let temporaryDirectory: TemporaryDirectory

    public init(
        deploymentId: String,
        deployables: [DeployableItem],
        deployableCommands: [DeployableCommand],
        destinations: [DeploymentDestination],
        cleanUpAutomatically: Bool = true) throws
    {
        self.deploymentId = deploymentId
        self.deployables = deployables
        self.deployableCommands = deployableCommands
        self.destinations = destinations
        temporaryDirectory = try TemporaryDirectory(
            dir: nil,
            prefix: "ru.avito.Deployer",
            removeTreeOnDeinit: cleanUpAutomatically)
    }
    
    /** Deploys all the deployable items and invokes deployment commands. */
    public func deploy() throws {
        let urlToDeployable = try prepareDeployables()
        try deployToDestinations(urlToDeployable: urlToDeployable)
    }
    
    /**
     * Packs all the Deployables and returns a map
     * from a URL with a package of the DeployableItem to a corresponding DeployableItem
     */
    private func prepareDeployables() throws -> [URL: DeployableItem] {
        let syncQueue = DispatchQueue(label: "ru.avito.Deployer.syncQueue")
        var deployablesFailedToPrepare = [DeployableItem]()
        var urlToDeployable = [URL: DeployableItem]()
        let packager = Packager()
        
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
                    log("Preparing deployable '\(deployable.name)'...")
                    let url = try packager.preparePackage(deployable: deployable, packageFolder: self.temporaryDirectory)
                    log("'\(deployable.name)' package path: \(url)")
                    syncQueue.sync { urlToDeployable[url] = deployable }
                } catch {
                    log("Failed to prepare deployable \(deployable.name): \(error)")
                    syncQueue.sync { deployablesFailedToPrepare.append(deployable) }
                }
                group.leave()
            }
        }
        group.wait()

        if !deployablesFailedToPrepare.isEmpty {
            throw DeploymentError.failedToPrepareDeployable(deployablesFailedToPrepare)
        }
        return urlToDeployable
    }
    
    /**
     * Subclasses should override this to perform their delivery logic.
     * @param   urlToDeployable   A map from local URL of package (zip) to a deployable item it represents.
     */
    open func deployToDestinations(urlToDeployable: [URL: DeployableItem]) throws {
        let errorMessage = "Deployer.deployToDestinations() must be overrided in subclass"
        log(errorMessage, color: .red)
        fatalError(errorMessage)
    }
}
