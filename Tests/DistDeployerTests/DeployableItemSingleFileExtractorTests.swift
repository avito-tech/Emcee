import Deployer
import DistDeployer
import Foundation
import XCTest

final class DeployableItemSingleFileExtractorTests: XCTestCase {
    private let deployableFile1 = DeployableFile(source: "source", destination: "destination")
    private let deployableFile2 = DeployableFile(source: "source2", destination: "destination2")
    
    private lazy var deployableItemWithSingleFile = DeployableItem(name: "name", files: [deployableFile1])
    private lazy var deployableItemWithMultipleFiles = DeployableItem(name: "name", files: [deployableFile1, deployableFile2])
    
    func test___getting_single_file_from_deployable_item() {
        let extractor = DeployableItemSingleFileExtractor(deployableItem: deployableItemWithSingleFile)
        XCTAssertEqual(try extractor.singleDeployableFile(), deployableFile1)
    }
    
    func test___getting_single_file_from_deployable_item_with_multiple_files_throws() {
        let extractor = DeployableItemSingleFileExtractor(deployableItem: deployableItemWithMultipleFiles)
        XCTAssertThrowsError(try extractor.singleDeployableFile())
    }
}

