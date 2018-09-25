import Foundation
import Extensions

public final class DeployableBundle: DeployableItem {
    
    public init(name: String, bundleUrl: URL) throws {
        super.init(
            name: name,
            files: try DeployableBundle.filesForBundle(bundleUrl: bundleUrl))
    }
    
    public static func filesForBundle(bundleUrl: URL) throws -> Set<DeployableFile> {
        let bundleName = bundleUrl.lastPathComponent
        var files: Set<DeployableFile> = [DeployableFile(source: bundleUrl.path, destination: bundleName)]
        
        guard let enumerator = FileManager.default.enumerator(at: bundleUrl.resolvingSymlinksInPath(), includingPropertiesForKeys: nil) else {
            throw DeploymentError.failedToEnumerateContentsOfDirectory(bundleUrl)
        }
        
        while let url = enumerator.nextObject() as? URL {
            let localPath: String
            let relativePath: String
            if let computedRelativePath = url.path.stringWithPathRelativeTo(anchorPath: bundleUrl.path, allowUpwardRelation: false) {
                localPath = url.path
                relativePath = computedRelativePath
            } else if let computedRelativePath = url.resolvingSymlinksInPath().path.stringWithPathRelativeTo(anchorPath: bundleUrl.path, allowUpwardRelation: false) {
                localPath = url.resolvingSymlinksInPath().path
                relativePath = computedRelativePath
            } else {
                throw DeploymentError.failedToRelativizePath(url.path, anchorPath: bundleUrl.path)
            }
            let destinationRelativePath = (bundleName as NSString).appendingPathComponent(relativePath)
            files.insert(DeployableFile(source: localPath, destination: destinationRelativePath))
        }
        
        return files
    }
}
