import EmceeLogging
import Foundation
import TypedResourceLocation
import PathLib
import UniqueIdentifierGenerator
import Zip

public final class LocalTypedResourceLocationPreparerImpl: LocalTypedResourceLocationPreparer {
    private let logger: ContextualLogger
    private let pathForStoringArchives: AbsolutePath
    private let remotelyAccessibleUrlForLocalFileProvider: RemotelyAccessibleUrlForLocalFileProvider
    private let zipCompressor: ZipCompressor
    private let uniqueIdentifierGenerator: UniqueIdentifierGenerator
    
    public init(
        logger: ContextualLogger,
        pathForStoringArchives: AbsolutePath,
        remotelyAccessibleUrlForLocalFileProvider: RemotelyAccessibleUrlForLocalFileProvider,
        uniqueIdentifierGenerator: UniqueIdentifierGenerator,
        zipCompressor: ZipCompressor
    ) {
        self.logger = logger
        self.pathForStoringArchives = pathForStoringArchives
        self.remotelyAccessibleUrlForLocalFileProvider = remotelyAccessibleUrlForLocalFileProvider
        self.uniqueIdentifierGenerator = uniqueIdentifierGenerator
        self.zipCompressor = zipCompressor
    }
    
    public func generateRemotelyAccessibleTypedResourceLocation<T: ResourceLocationType>(
        _ from: TypedResourceLocation<T>
    ) throws -> TypedResourceLocation<T> {
        return try TypedResourceLocation<T>(
            from.resourceLocation.mapLocalFile { value in
                let localPath = try AbsolutePath.validating(string: value)
                logger.debug("Preparing local file at \(value) to be accessible remotely")
                
                let archivePath = try zipCompressor.createArchive(
                    archivePath: pathForStoringArchives
                        .appending(uniqueIdentifierGenerator.generate())
                        .appending(extension: "zip"),
                    workingDirectory: localPath.removingLastComponent,
                    contentsToCompress: RelativePath(localPath.lastComponent)
                )
                
                logger.debug("Generated archive at \(archivePath)")
                let url = try remotelyAccessibleUrlForLocalFileProvider.remotelyAccessibleUrlForLocalFile(
                    archivePath: archivePath,
                    inArchivePath: RelativePath(localPath.lastComponent)
                )
                
                logger.debug("Archive should be accessible via URL: \(url)")
                return .remoteUrl(url, nil)
            }
        )
    }
}
