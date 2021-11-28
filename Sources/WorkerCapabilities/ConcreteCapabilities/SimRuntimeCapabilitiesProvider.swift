import FileSystem
import Foundation
import EmceeLogging
import PathLib
import PlistLib
import WorkerCapabilitiesModels

public final class SimRuntimeCapabilitiesProvider: WorkerCapabilitiesProvider {
    private let fileSystem: FileSystem
    private let logger: ContextualLogger
    
    public init(
        fileSystem: FileSystem,
        logger: ContextualLogger
    ) {
        self.fileSystem = fileSystem
        self.logger = logger
    }
    
    /// Returns capability name based on SimRuntime bundle id.
    /// - Parameters:
    ///   - simRuntimeBundleIdentifier: Bundle id from `Info.plist`of `.simruntime` bundle. E.g. `com.apple.CoreSimulator.SimRuntime.tvOS-10-2`
    /// - Returns: Worker capability name for provided simruntime.
    public static func workerCapabilityName(simRuntimeBundleIdentifier: String) -> WorkerCapabilityName {
        WorkerCapabilityName(simRuntimeBundleIdentifier)
    }
    
    public func workerCapabilities() -> Set<WorkerCapability> {
        Set(
            discoverSimRuntimes().map { discoveredSimRuntime in
                WorkerCapability(
                    name: Self.workerCapabilityName(simRuntimeBundleIdentifier: discoveredSimRuntime.bundleIdentifier),
                    value: discoveredSimRuntime.bundleName
                )
            }
        )
    }
    
    private struct DiscoveredSimRuntime {
        let path: AbsolutePath
        let bundleIdentifier: String
        let bundleName: String
    }
    
    private func discoverSimRuntimes() -> [DiscoveredSimRuntime] {
        do {
            let runtimesFolder = try fileSystem.library(
                inDomain: .local,
                create: false
            ).appending(
                relativePath: "Developer/CoreSimulator/Profiles/Runtimes/"
            )
            let enumerator = fileSystem.contentEnumerator(forPath: runtimesFolder, style: .shallow)
            
            var discoveredSimRuntimes = [DiscoveredSimRuntime]()
            
            try enumerator.each { path in
                do {
                    guard path.extension == "simruntime" else { return }
                    
                    let plistPath = path.appending(components: ["Contents", "Info.plist"])
                    let plist = try Plist.create(fromData: Data(contentsOf: plistPath.fileUrl, options: .mappedIfSafe))
                    
                    discoveredSimRuntimes.append(
                        DiscoveredSimRuntime(
                            path: path,
                            bundleIdentifier: try plist.root.plistEntry.entry(forKey: "CFBundleIdentifier").stringValue(),
                            bundleName: try plist.root.plistEntry.entry(forKey: "CFBundleName").stringValue()
                        )
                    )
                } catch {
                    logger.error("Error while discovering simruntime at path \(path): \(error)")
                }
            }
            
            return discoveredSimRuntimes
        } catch {
            logger.error("Error discovering simruntimes: \(error)")
            return []
        }
    }
}
