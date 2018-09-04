import Foundation

public enum DeploymentError: Error, CustomStringConvertible {
    case unableToObtainInfoAboutFile(DeployableFile)
    case unableToCreateArchive(URL)
    case failedToEnumerateContentsOfDirectory(URL)
    case failedToRelativizePath(String, anchorPath: String)
    case failedToPrepareDeployable([DeployableItem])
    case failedToDeployToDestination([DeploymentDestination])
    
    public var description: String {
        switch self {
        case .unableToObtainInfoAboutFile(let deployableFile):
            return "Unable to obtain info about deployable file: '\(deployableFile)'"
        case .unableToCreateArchive(let url):
            return "Unable to create archive at: '\(url)'"
        case .failedToEnumerateContentsOfDirectory(let url):
            return "Failed to enumerate contents of directory: '\(url)'"
        case .failedToRelativizePath(let path, let anchorPath):
            return "Failed to build a relative path for '\(path)', anchor: '\(anchorPath)'"
        case .failedToPrepareDeployable(let deployableItems):
            return "Failed to prepare deployable items: \(deployableItems)"
        case .failedToDeployToDestination(let deploymentDestinations):
            return "Failed to deploy to destinations: \(deploymentDestinations)"
        }
    }
}
