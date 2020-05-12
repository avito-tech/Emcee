import Foundation
import Models
import PathLib
import ProcessController

public final class DefaultDeveloperDirLocator: DeveloperDirLocator {
    private let processControllerProvider: ProcessControllerProvider
    private let xcodeAppContainerPath: AbsolutePath
    
    public init(
        processControllerProvider: ProcessControllerProvider,
        xcodeAppContainerPath: AbsolutePath = AbsolutePath("/Applications/")
    ) {
        self.processControllerProvider = processControllerProvider
        self.xcodeAppContainerPath = xcodeAppContainerPath
    }
    
    public func path(developerDir: DeveloperDir) throws -> AbsolutePath {
        switch developerDir {
        case .current:
            return try xcodeSelectProvidedDeveloperDir()
        case .useXcode(let CFBundleShortVersionString):
            return try findDeveloperDir(
                containerPath: xcodeAppContainerPath,
                xcodeCFBundleShortVersionString: CFBundleShortVersionString
            )
        }
    }
    
    private func xcodeSelectProvidedDeveloperDir() throws -> AbsolutePath {
        let processController = try processControllerProvider.createProcessController(
            subprocess: Subprocess(arguments: ["/usr/bin/xcode-select", "-p"])
        )
        try processController.startAndListenUntilProcessDies()
        let path = try String(contentsOf: processController.subprocess.standardStreamsCaptureConfig.stdoutContentsFile.fileUrl)
        return AbsolutePath(path.trimmingCharacters(in: .whitespacesAndNewlines))
    }
    
    private func findDeveloperDir(
        containerPath: AbsolutePath,
        xcodeCFBundleShortVersionString: String
    ) throws -> AbsolutePath {
        let xcodePath = try suitableXcodePath(
            paths: try findXcodePaths(path: containerPath),
            CFBundleShortVersionString: xcodeCFBundleShortVersionString
        )
        return xcodePath.appending(components: ["Contents", "Developer"])
    }
    
    private func findXcodePaths(path: AbsolutePath) throws -> [AbsolutePath] {
        let potentialXcodePaths = try FileManager.default.contentsOfDirectory(atPath: path.pathString)
            .filter { $0.hasPrefix("Xcode") }
            .map { path.appending(component: $0) }
        return potentialXcodePaths
    }
    
    private func suitableXcodePath(
        paths: [AbsolutePath],
        CFBundleShortVersionString: String
    ) throws -> AbsolutePath {
        for xcodePath in paths {
            let plistPath = xcodePath.appending(components: ["Contents", "Info.plist"])
            guard let plist = NSDictionary(contentsOf: plistPath.fileUrl) else {
                throw DeveloperDirLocatorError.unableToLoadPlist(path: plistPath)
            }
            guard let value = plist["CFBundleShortVersionString"], let version = value as? String else {
                throw DeveloperDirLocatorError.plistDoesNotContainCFBundleShortVersionString(path: plistPath)
            }
            if version == CFBundleShortVersionString {
                return xcodePath
            }
        }
        throw DeveloperDirLocatorError.noSuitableXcode(CFBundleShortVersionString: CFBundleShortVersionString)
    }
}
