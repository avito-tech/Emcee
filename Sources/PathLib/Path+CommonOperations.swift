import Foundation

public extension Path {
    init(_ fileUrl: URL) {
        self.init(components: StringPathParsing.components(path: fileUrl.path))
    }
    
    init(_ path: String) {
        self.init(components: StringPathParsing.components(path: path))
    }
    
    func appending(components: [String]) -> Self {
        return Self(components: self.components + components)
    }
    
    func appending(relativePath: RelativePath) -> Self {
        return Self(components: components + relativePath.components)
    }
    
    func appending(component: String) -> Self {
        return Self(components: self.components + [component])
    }
    
    var removingLastComponent: Self {
        guard components.count > 0 else {
            return self
        }
        return Self(components: Array(components.dropLast()))
    }
    
    var lastComponent: String {
        guard let result = components.last else {
            return pathString
        }
        return result
    }
    
    /// Deletes the filename portion, beginning with the last slash `/' character to the end of string
    var dirname: String {
        return removingLastComponent.pathString
    }
    
    /// Deletes any prefix ending with the last slash `/' character present in string (after firs stripping trailing slashes)
    var basename: String {
        return lastComponent
    }
    
    /// Returns a suffix after the last dot symbol in basename. Returns empty string if there is no extension.
    /// Correctly handles hidden heading dot ("`.file`" - extension is empty).
    var `extension`: String {
        let component = lastComponent
        guard let dotPosition = component.lastIndex(of: ".") else {
            return ""
        }
        if component.starts(with: "."), component.startIndex == dotPosition {
            return ""
        }
        return String(component.suffix(from: component.index(after: dotPosition)))
    }
}
