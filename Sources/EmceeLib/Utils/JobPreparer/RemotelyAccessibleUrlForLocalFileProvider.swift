import Foundation
import PathLib

public protocol RemotelyAccessibleUrlForLocalFileProvider {
    func remotelyAccessibleUrlForLocalFile(
        archivePath: AbsolutePath,
        inArchivePath: RelativePath
    ) throws -> URL
}
