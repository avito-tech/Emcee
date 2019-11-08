import Foundation
import Logging
import Models
import PathLib

public final class FbxctestSimFolderCreator {
    public init() {}
    
    public func createSimFolderForFbxctest(
        containerPath: AbsolutePath,
        simulatorPath: AbsolutePath
    ) throws -> AbsolutePath {
        let simFolderPath = containerPath.appending(component: "sim")
        try FileManager.default.createDirectory(atPath: simFolderPath)
        
        let sourcePath = simFolderPath.appending(component: simulatorPath.lastComponent)
        
        Logger.debug("Creating simulator environment for fbxctest: mapping \(sourcePath) -> \(simulatorPath)")
        try FileManager.default.createSymbolicLink(
            atPath: sourcePath.pathString,
            withDestinationPath: simulatorPath.pathString
        )
        
        let deviceSetPlistPath = simFolderPath.appending(component: "device_set.plist")
        Logger.debug("Creating fake device_set.plist at \(deviceSetPlistPath)")
        try createDeviceSetPlist(path: deviceSetPlistPath)
        
        return containerPath
    }
    
    public func cleanUpSimFolder(simFolderPath: AbsolutePath) throws {
        let tmp = simFolderPath.appending(component: "tmp")
        if FileManager.default.fileExists(atPath: tmp.pathString) {
            Logger.debug("Cleaning up fbxctest tmp folder: \(tmp)")
            try FileManager.default.removeItem(atPath: tmp.pathString)
        }
    }

    private func createDeviceSetPlist(path: AbsolutePath) throws {
        try savePlist(
            contents: FbxctestSimFolderCreator.deviceSetPlistContents(),
            path: path
        )
    }

    private static func deviceSetPlistContents() -> [String: Any] {
        return [
            "DefaultDevices": [
                "version": 0
            ],
            "Version": 0,
            "DevicePairs": [:]
        ]
    }

    private func savePlist(contents: [String: Any], path: AbsolutePath) throws {
        let data = try PropertyListSerialization.data(
            fromPropertyList: contents as NSDictionary,
            format: .xml,
            options: 0
        )
        try data.write(to: path.fileUrl, options: [])
    }
}
