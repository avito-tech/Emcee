import Foundation
import PathLib

public enum DeploymentError: Error, CustomStringConvertible {
    case unableToObtainInfoAboutFile(DeployableFile)
    case unableToCreateArchive(AbsolutePath)
    case failedToEnumerateContentsOfDirectory(AbsolutePath)
    case failedToRelativizePath(AbsolutePath, anchorPath: AbsolutePath)
    case failedToPrepareDeployable([DeployableItem])
    
    public var description: String {
        switch self {
        case .unableToObtainInfoAboutFile(let deployableFile):
            return "Unable to obtain info about deployable file: '\(deployableFile)'"
        case .unableToCreateArchive(let path):
            return "Unable to create archive at: '\(path)'"
        case .failedToEnumerateContentsOfDirectory(let path):
            return "Failed to enumerate contents of directory: '\(path)'"
        case .failedToRelativizePath(let path, let anchorPath):
            return "Failed to build a relative path for '\(path)', anchor: '\(anchorPath)'"
        case .failedToPrepareDeployable(let deployableItems):
            return "Failed to prepare deployable items: \(deployableItems)"
        }
    }
}
