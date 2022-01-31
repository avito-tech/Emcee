import Foundation
import FileSystem
import PathLib

public extension FileSystem {
    func emceeLogsFolder() throws -> AbsolutePath {
        let libraryPath = try commonlyUsedPathsProvider.library(inDomain: .user, create: false)
        return libraryPath.appending("Logs", "ru.avito.emcee.logs")
    }
    
    func emceeLogsCleanUpMarkerFile() throws -> AbsolutePath {
        let path = try emceeLogsFolder().appending("logs_cleanup_marker")
        if !properties(forFileAtPath: path).exists() {
            try createFile(path: path, data: nil)
        }
        return path
    }
    
    func folderForStoringLogs(processName: String) throws -> AbsolutePath {
        let container = try emceeLogsFolder().appending(processName)
        try createDirectory(path: container, withIntermediateDirectories: true)
        
        return container
    }
}
