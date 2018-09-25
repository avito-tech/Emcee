import Foundation
import Extensions

public final class DeployableBundle: DeployableItem {
    
    public init(name: String, bundleUrl: URL) throws {
        super.init(
            name: name,
            files: try DeployableBundle.filesForBundle(bundleUrl: bundleUrl))
    }
    
    public static func filesForBundle(bundleUrl: URL) throws -> Set<DeployableFile> {
        return try filesForBundle(withResolvedSymlinksBundleUrl: bundleUrl.resolvingSymlinksInPath())
    }
    
    private static func filesForBundle(withResolvedSymlinksBundleUrl bundleUrl: URL) throws -> Set<DeployableFile> {
        let bundleName = bundleUrl.lastPathComponent
        var files: Set<DeployableFile> = [DeployableFile(source: bundleUrl.path, destination: bundleName)]
        
        guard let enumerator = FileManager.default.enumerator(at: bundleUrl, includingPropertiesForKeys: nil) else {
            throw DeploymentError.failedToEnumerateContentsOfDirectory(bundleUrl)
        }
        
        while let url = enumerator.nextObject() as? URL {
            let localPath = url.resolvingSymlinksInPath().path
            guard let relativePath = localPath.stringWithPathRelativeTo(anchorPath: bundleUrl.path) else {
                throw DeploymentError.failedToRelativizePath(localPath, anchorPath: bundleUrl.path)
            }
            let destinationRelativePath = (bundleName as NSString).appendingPathComponent(relativePath)
            files.insert(DeployableFile(source: localPath, destination: destinationRelativePath))
        }
        
        return files
    }
}
