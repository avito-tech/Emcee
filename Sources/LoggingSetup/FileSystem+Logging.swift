import Foundation
import FileSystem
import PathLib

public extension FileSystem {
    func emceeLogsFolder() throws -> AbsolutePath {
        let libraryPath = try commonlyUsedPathsProvider.library(inDomain: .user, create: false)
        return libraryPath.appending(components: ["Logs", "ru.avito.emcee.logs"])
    }
    
    func folderForStoringLogs(processName: String) throws -> AbsolutePath {
        let container = try emceeLogsFolder().appending(component: processName)
        try createDirectory(atPath: container, withIntermediateDirectories: true)
        
        return container
    }
}
