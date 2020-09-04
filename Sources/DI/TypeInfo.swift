import Foundation

public struct TypeInfo: Hashable, Equatable, CustomStringConvertible {
    public let moduleName: String
    public let typeName: String
    
    // MARK: - Init
    public init(moduleName: String, typeName: String) {
        self.moduleName = moduleName
        self.typeName = typeName
    }
    
    public init(_ type: Any.Type) {
        let typeDescription = TypeInfo.description(of: type)
        self.init(typeDescription)
    }
    
    public init(_ typeDescription: String) {
        let (moduleName, typeName) = TypeInfo.parse(typeDescription: typeDescription)
        
        self.init(
            moduleName: moduleName,
            typeName: typeName
        )
    }
    
    // MARK: - Public
    public func removingModuleName() -> TypeInfo {
        return TypeInfo(
            moduleName: "",
            typeName: typeName
        )
    }
    
    // MARK: - Public static
    public static func description(of type: Any.Type) -> String {
        return String(reflecting: type) // Returns "Module.Type"
        // and String(describing: type) // Returns "Type"
    }
    
    public var description: String {
        moduleName.isEmpty ? typeName : "\(moduleName).\(typeName)"
    }
    
    // MARK: - Private static
    private static func parse(typeDescription: String) -> (moduleName: String, typeName: String) {
        guard let dotIndex = typeDescription.firstIndex(of: ".") else {
            return ("", typeDescription)
        }
        
        let moduleName = typeDescription[typeDescription.startIndex..<dotIndex]
        let typeName = typeDescription[typeDescription.index(after: dotIndex)...]
        
        return (String(moduleName), String(typeName))
    }
}
