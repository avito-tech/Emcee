import Models
import PathLib

public protocol DeveloperDirLocator {
    func path(developerDir: DeveloperDir) throws -> AbsolutePath
}

public extension DeveloperDirLocator {
    func suitableEnvironment(
        forDeveloperDir developerDir: DeveloperDir,
        byUpdatingEnvironment env: [String: String] = [:]
    ) throws -> [String: String] {
        var env = env
        env["DEVELOPER_DIR"] = try path(developerDir: developerDir).pathString
        return env
    }
}
