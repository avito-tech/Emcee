import FileSystem
import Foundation

public protocol FileSystemProvider {
    func create() -> FileSystem
}

public final class LocalFileSystemProvider: FileSystemProvider {
    public init() {}
    
    public func create() -> FileSystem {
        let fileManager = FileManager()
        let fileCreator = FileCreatorImpl(
            fileManager: fileManager
        )
        let filePropertiesProvider = FilePropertiesProviderImpl()
        let directoryCreator = DirectoryCreatorImpl(
            fileManager: fileManager,
            filePropertiesProvider: filePropertiesProvider
        )
        let pathDeleter = PathDeleterImpl(
            fileManager: fileManager,
            filePropertiesProvider: filePropertiesProvider
        )
        let pathCopier = PathCopierImpl(
            fileManager: fileManager,
            pathDeleter: pathDeleter,
            directoryCreator: directoryCreator
        )
        let pathMover = PathMoverImpl(
            fileManager: fileManager,
            pathDeleter: pathDeleter,
            directoryCreator: directoryCreator
        )
        
        return LocalFileSystem(
            fileSystemEnumeratorFactory: FileSystemEnumeratorFactoryImpl(
                fileManager: fileManager,
                filePropertiesProvider: filePropertiesProvider
            ),
            directoryCreator: directoryCreator,
            fileCreator: fileCreator,
            pathCopier: pathCopier,
            pathMover: pathMover,
            pathDeleter: pathDeleter,
            filePropertiesProvider: filePropertiesProvider,
            fileSystemPropertiesProvider: FileSystemPropertiesProviderImpl(),
            commonlyUsedPathsProviderFactory: CommonlyUsedPathsProviderFactoryImpl(
                fileManager: fileManager
            ),
            fileToucher: FileToucherImpl(
                filePropertiesProvider: filePropertiesProvider,
                fileCreator: fileCreator
            )
        )
    }
}
