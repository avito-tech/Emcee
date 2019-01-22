import Deployer
import Foundation

public final class DeployableItemSingleFileExtractor {
    private let deployableItem: DeployableItem
    
    public enum DeployableItemSingleFileExtractorError: Error, CustomStringConvertible {
        case unexpectedNumberOfFiles(DeployableItem)
        
        public var description: String {
            switch self {
            case .unexpectedNumberOfFiles(let item):
                return "Unexpected number of files in deployable \(item): expected to have a single file, but \(item.files.count) files found: \(item.files)"
            }
        }
    }

    public init(deployableItem: DeployableItem) {
        self.deployableItem = deployableItem
    }
    
    public func singleDeployableFile() throws -> DeployableFile {
        guard deployableItem.files.count == 1,
            let file = deployableItem.files.first else
        {
            throw DeployableItemSingleFileExtractorError.unexpectedNumberOfFiles(deployableItem)
        }
        return file
    }
}
