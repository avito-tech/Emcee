import AtomicModels
import Foundation

public final class DIImpl: DI {
    private let storage = AtomicValue<[TypeInfo: () -> Any]>([:])
    
    private enum DIError: Error, CustomStringConvertible {
        case noConstructor(TypeInfo)
        case typeMismatch(TypeInfo, value: Any)
        
        var description: String {
            switch self {
            case .noConstructor(let typeInfo):
                return "No constructor defined for \(typeInfo)"
            case .typeMismatch(let typeInfo, let value):
                return "Value for \(typeInfo) has unexpected type: \(value) (type \(type(of: value))"
            }
        }
    }
    
    public init() {}
    
    public func get<T>(_ type: T.Type) throws -> T {
        let key = TypeInfo(type)
        
        guard let constructor = storage.currentValue()[key] else {
            throw DIError.noConstructor(key)
        }
        let value = constructor()
        guard let castedValue = value as? T else {
            throw DIError.typeMismatch(key, value: value)
        }
        return castedValue
    }
    
    public func register<T>(_ type: T.Type, constructor: @escaping () -> T) {
        let key = TypeInfo(type)
        storage.withExclusiveAccess {
            $0[key] = { constructor() }
        }
    }
}
