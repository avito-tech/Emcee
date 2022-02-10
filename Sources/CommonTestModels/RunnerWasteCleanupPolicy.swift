import Foundation

public enum RunnerWasteCleanupPolicy: String, Codable, Hashable, CustomStringConvertible {
    /// Clean up all temporary and auxiliary files
    case clean
    
    /// Keep all temporary and auxiliary files intact.
    case keep
    
    public var description: String { rawValue }
}
