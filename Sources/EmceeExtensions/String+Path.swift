import Foundation

public extension String {
    var bridged: NSString {
        return self as NSString
    }
    
    var pathComponents: [String] {
        return bridged.pathComponents
    }
    
    func appending(pathComponent: String) -> String {
        return bridged.appendingPathComponent(pathComponent)
    }
    
    func appending(pathComponents: [String]) -> String {
        var string = self
        for component in pathComponents {
            string = string.appending(pathComponent: component)
        }
        return string 
    }
    
    var pathExtension: String {
        return bridged.pathExtension
    }
    
    var deletingPathExtension: String {
        return bridged.deletingPathExtension
    }
    
    var lastPathComponent: String {
        return bridged.lastPathComponent
    }
    
    var deletingLastPathComponent: String {
        return bridged.deletingLastPathComponent
    }
    
    /**
     * Attempts to create a path relative to a given anchor (or base) path.
     *
     * self: "~/Library/Developer/Xcode"
     * anchorPath: "~/Library/Developer"
     * self relative to anchorPath: "Xcode"
     *
     * self: "~/Library/Developer"
     * anchorPath: "~/Library/Developer/Xcode"
     * self relative to anchorPath: "../"
     */
    func stringWithPathRelativeTo(anchorPath: String, allowUpwardRelation: Bool = true) -> String? {
        let pathComponents = self.pathComponents
        let anchorComponents = anchorPath.pathComponents
        
        var componentsInCommon = 0
        for (c1, c2) in zip(pathComponents, anchorComponents) {
            if c1 != c2 {
                break
            }
            componentsInCommon += 1
        }
        
        let numberOfParentComponents = anchorComponents.count - componentsInCommon
        let numberOfPathComponents = pathComponents.count - componentsInCommon
        
        var relativeComponents = [String]()
        relativeComponents.reserveCapacity(numberOfParentComponents + numberOfPathComponents)
        for _ in 0..<numberOfParentComponents {
            if !allowUpwardRelation {
                return nil
            }
            relativeComponents.append("..")
        }
        relativeComponents.append(contentsOf: pathComponents[componentsInCommon..<pathComponents.count])
        
        let url = NSURL.fileURL(withPathComponents: relativeComponents)
        return url?.relativePath
    }
}
