import Foundation

public final class ArgumentDescription: Hashable, CustomStringConvertible {
    public let name: ArgumentName
    public let overview: String
    public let multiple: Bool
    public let optional: Bool
    
    public init(
        name: ArgumentName,
        overview: String,
        multiple: Bool = false,
        optional: Bool = false
    ) {
        self.name = name
        self.overview = overview
        self.multiple = multiple
        self.optional = optional
    }
    
    public var description: String {
        return "<\(name) \(multiple ? "multiple" : "single") \(optional ? "optional" : "required")>"
    }
    
    public static func == (left: ArgumentDescription, right: ArgumentDescription) -> Bool {
        return left.name == right.name
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
    
    public var asOptional: ArgumentDescription {
        return ArgumentDescription(name: name, overview: overview, multiple: multiple, optional: true)
    }
    
    public var asRequired: ArgumentDescription {
        return ArgumentDescription(name: name, overview: overview, multiple: multiple, optional: false)
    }
    
    public var usage: String {
        var usage = "\(name.expectedInputValue)   --   \(overview)"
        if usage.last != "." { usage += "." }
        if multiple {
            usage += " This argument may be repeated multiple times."
        }
        if optional {
            usage += " Optional."
        } else {
            usage += " Required."
        }
        return usage
    }
}
