import Models
import PathLib

public protocol DeveloperDirLocator {
    func path(developerDir: DeveloperDir) throws -> AbsolutePath
}
