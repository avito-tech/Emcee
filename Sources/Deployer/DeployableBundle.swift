import Foundation
import Extensions
import PathLib

public final class DeployableBundle: DeployableItem {
    
    public init(name: String, bundlePath: AbsolutePath) throws {
        super.init(
            name: name,
            files: try DeployableBundle.filesForBundle(bundlePath: bundlePath)
        )
    }
    
    public static func filesForBundle(bundlePath: AbsolutePath) throws -> Set<DeployableFile> {
        let bundleName = bundlePath.lastComponent
        var files: Set<DeployableFile> = [DeployableFile(source: bundlePath, destination: RelativePath(bundleName))]
        
        guard let enumerator = FileManager.default.enumerator(at: bundlePath.fileUrl.resolvingSymlinksInPath(), includingPropertiesForKeys: nil) else {
            throw DeploymentError.failedToEnumerateContentsOfDirectory(bundlePath)
        }
        
        while let url = enumerator.nextObject() as? URL {
            let localPath: AbsolutePath
            let relativePath: RelativePath
            if let computedRelativePath = url.path.stringWithPathRelativeTo(anchorPath: bundlePath.pathString, allowUpwardRelation: false) {
                localPath = AbsolutePath(url.path)
                relativePath = RelativePath(computedRelativePath)
            } else if let computedRelativePath = url.resolvingSymlinksInPath().path.stringWithPathRelativeTo(anchorPath: bundlePath.pathString, allowUpwardRelation: false) {
                localPath = AbsolutePath(url.resolvingSymlinksInPath().path)
                relativePath = RelativePath(computedRelativePath)
            } else {
                throw DeploymentError.failedToRelativizePath(AbsolutePath(url.path), anchorPath: bundlePath)
            }
            let destinationRelativePath = RelativePath(bundleName).appending(relativePath: relativePath)
            files.insert(DeployableFile(source: localPath, destination: destinationRelativePath))
        }
        
        return files
    }
}
