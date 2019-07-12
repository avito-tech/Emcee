import Foundation

public final class CommandPayload: CustomStringConvertible {
    public let valueHolders: [ArgumentValueHolder]
    
    public init(valueHolders: [ArgumentValueHolder]) {
        self.valueHolders = valueHolders
    }
    
    public var description: String {
        return "\(type(of: self)): \(valueHolders)"
    }
    
    public func expectedValueHolders(
        argumentName: ArgumentName
    ) throws -> [ArgumentValueHolder] {
        let matchingHolders = valueHolders.filter { $0.argumentName == argumentName }
        guard !matchingHolders.isEmpty else {
            throw ArgumentsError.argumentMissing(argumentName)
        }
        return matchingHolders
    }
    
    public func optionalValueHolders(
        argumentName: ArgumentName
    ) throws -> [ArgumentValueHolder] {
        do {
            return try expectedValueHolders(argumentName: argumentName)
        } catch {
            if case ArgumentsError.argumentMissing = error {
                return []
            } else {
                throw error
            }
        }
    }
    
    // MARK: - Single value arguments
    
    public func expectedSingleTypedValue<T: ParsableArgument>(
        argumentName: ArgumentName
    ) throws -> T {
        let valueHolders = try expectedValueHolders(argumentName: argumentName)
        guard valueHolders.count == 1, let valueHolder = valueHolders.first else {
            throw ArgumentsError.multipleValuesFound(argumentName, values: valueHolders.map { $0.stringValue })
        }
        return try valueHolder.typedValue()
    }
    
    public func optionalSingleTypedValue<T: ParsableArgument>(
        argumentName: ArgumentName
    ) throws -> T? {
        let valueHolders = try optionalValueHolders(argumentName: argumentName)
        guard valueHolders.count <= 1 else {
            throw ArgumentsError.multipleValuesFound(argumentName, values: valueHolders.map { $0.stringValue })
        }
        return try valueHolders.first?.typedValue()
    }
    
    // MARK: - Multiple arguments
    
    public func nonEmptyCollectionOfValues<T: ParsableArgument>(
        argumentName: ArgumentName
    ) throws -> [T] {
        let valueHolders = try expectedValueHolders(argumentName: argumentName)
        return try valueHolders.map { try $0.typedValue() }
    }
    
    public func possiblyEmptyCollectionOfValues<T: ParsableArgument>(
        argumentName: ArgumentName
    ) throws -> [T] {
        let valueHolders = try optionalValueHolders(argumentName: argumentName)
        return try valueHolders.map { try $0.typedValue() }
    }
}
