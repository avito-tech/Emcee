import Deployer
import DistDeployer
import Foundation
import PathLib
import XCTest

final class DeployableItemSingleFileExtractorTests: XCTestCase {
    private let deployableFile1 = DeployableFile(
        source: AbsolutePath("source"),
        destination: RelativePath("destination")
    )
    private let deployableFile2 = DeployableFile(
        source: AbsolutePath("source2"),
        destination: RelativePath("destination2")
    )
    
    private lazy var deployableItemWithSingleFile = DeployableItem(
        name: "name",
        files: [deployableFile1]
    )
    private lazy var deployableItemWithMultipleFiles = DeployableItem(
        name: "name",
        files: [deployableFile1, deployableFile2]
    )
    
    func test___getting_single_file_from_deployable_item() {
        let extractor = DeployableItemSingleFileExtractor(deployableItem: deployableItemWithSingleFile)
        XCTAssertEqual(try extractor.singleDeployableFile(), deployableFile1)
    }
    
    func test___getting_single_file_from_deployable_item_with_multiple_files_throws() {
        let extractor = DeployableItemSingleFileExtractor(deployableItem: deployableItemWithMultipleFiles)
        XCTAssertThrowsError(try extractor.singleDeployableFile())
    }
}
