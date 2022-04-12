import Foundation
import Runner
import PathLib

open class FakeResultBundleUploader: ResultBundleUploader {
    
    public init() {
    }
    
    public private(set) var uploadedResultBundles: [(AbsolutePath, URL)] = []
    
    public func uploadResultBundle(
        zippedResultBundleOutputPath: AbsolutePath,
        resultBundlesUploadUrl: URL
    ) {
        uploadedResultBundles.append((zippedResultBundleOutputPath, resultBundlesUploadUrl))
    }
    
}
