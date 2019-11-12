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
    
    public func cleanUpSimFolder(simFolderPath: AbsolutePath) {
        let tmp = simFolderPath.appending(component: "tmp")
        if FileManager.default.fileExists(atPath: tmp.pathString) {
            Logger.debug("Removing 'tmp' folder: \(tmp)")
            try? FileManager.default.removeItem(atPath: tmp.pathString)
        }
        
        let sim = simFolderPath.appending(component: "sim")
        if FileManager.default.fileExists(atPath: sim.pathString) {
            Logger.debug("Removing 'sim' folder: \(sim)")
            try? FileManager.default.removeItem(atPath: sim.pathString)
        }
        
        do {
            Logger.debug("Removing fbxctest simulator folder: \(sim)")
            try FileManager.default.removeItem(atPath: simFolderPath.pathString)
        } catch {
            Logger.warning("Failed to delete fbxctest simulator folder: \(error)")
            FbxctestSimFolderCreator.removeFolderAfterDelay(simFolderPath: simFolderPath)
        }
    }
    
    private static func removeFolderAfterDelay(simFolderPath: AbsolutePath) {
        DispatchQueue.global().asyncAfter(deadline: .now() + 5.0) {
            if FileManager.default.fileExists(atPath: simFolderPath.pathString) {
                Logger.debug("Removing fbxctest simulator folder last time: \(simFolderPath)")
                do {
                    try FileManager.default.removeItem(atPath: simFolderPath.pathString)
                } catch {
                    Logger.warning("Failed to delete fbxctest simulator folder after all attempts: \(error)")
                }
            }
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
