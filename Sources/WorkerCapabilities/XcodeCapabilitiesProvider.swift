import FileSystem
import Foundation
import EmceeLogging
import PathLib
import PlistLib
import WorkerCapabilitiesModels

public final class XcodeCapabilitiesProvider: WorkerCapabilitiesProvider {
    private let fileSystem: FileSystem
    private let logger: ContextualLogger
    
    public init(
        fileSystem: FileSystem,
        logger: ContextualLogger
    ) {
        self.fileSystem = fileSystem
        self.logger = logger.forType(Self.self)
    }
    
    public static func workerCapabilityName(shortVersion: String) -> WorkerCapabilityName {
        WorkerCapabilityName("emcee.dt.xcode.\(shortVersion.replacingOccurrences(of: ".", with: "_"))")
    }
    
    public func workerCapabilities() -> Set<WorkerCapability> {
        Set(
            discoverXcodes().map { discoveredXcode in
                WorkerCapability(
                    name: XcodeCapabilitiesProvider.workerCapabilityName(shortVersion: discoveredXcode.shortVersion),
                    value: discoveredXcode.shortVersion
                )
            }
        )
    }
    
    private struct DiscoveredXcode {
        let path: AbsolutePath
        let shortVersion: String
    }
    
    private func discoverXcodes() -> [DiscoveredXcode] {
        do {
            let applicationsFolder = try fileSystem.commonlyUsedPathsProvider.applications(inDomain: .local, create: false)
            let enumerator = fileSystem.contentEnumerator(forPath: applicationsFolder, style: .shallow)
            
            var discoveredXcodes = [DiscoveredXcode]()
            
            try enumerator.each { path in
                do {
                    guard path.lastComponent.contains("Xcode") || path.lastComponent.contains("xcode") else { return }
                    let plistPath = path.appending(components: ["Contents", "Info.plist"])
                    let plist = try Plist.create(fromData: Data(contentsOf: plistPath.fileUrl, options: .mappedIfSafe))
                    guard try plist.root.plistEntry.entry(forKey: "CFBundleIdentifier").stringValue() == "com.apple.dt.Xcode" else { return }
                    let shortVersion = try plist.root.plistEntry.entry(forKey: "CFBundleShortVersionString").stringValue()
                    discoveredXcodes.append(
                        DiscoveredXcode(
                            path: path,
                            shortVersion: shortVersion
                        )
                    )
                } catch {
                    logger.error("Error while discovering Xcode at path \(path): \(error)")
                }
            }
            
            return discoveredXcodes
        } catch {
            logger.error("Error discovering Xcodes: \(error)")
            return []
        }
    }
}
