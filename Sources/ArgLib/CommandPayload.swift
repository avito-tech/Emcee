import Foundation

public final class CommandPayload: CustomStringConvertible {
    public let valueHolders: Set<ArgumentValueHolder>
    
    public init(valueHolders: Set<ArgumentValueHolder>) {
        self.valueHolders = valueHolders
    }
    
    public var description: String {
        let sortedHolders = valueHolders.sorted { (left, right) -> Bool in
            left.argumentName.expectedInputValue < right.argumentName.expectedInputValue
        }
        return "\(type(of: self)): \(sortedHolders)"
    }
    
    public func expectedValueHolder(
        argumentName: ArgumentName
    ) throws -> ArgumentValueHolder {
        guard let valueHolder = valueHolders.first(where: { $0.argumentName == argumentName }) else {
            throw ArgumentsError.argumentMissing(argumentName)
        }
        return valueHolder
    }
    
    public func optionalValueHolder(
        argumentName: ArgumentName
    ) throws -> ArgumentValueHolder? {
        do {
            return try expectedValueHolder(argumentName: argumentName)
        } catch {
            if case ArgumentsError.argumentMissing = error {
                return nil
            } else {
                throw error
            }
        }
    }
    
    public func expectedTypedValue<T: ParsableArgument>(
        argumentName: ArgumentName
    ) throws -> T {
        let valueHolder = try expectedValueHolder(argumentName: argumentName)
        return try valueHolder.typedValue()
    }
    
    public func optionalTypedValue<T: ParsableArgument>(
        argumentName: ArgumentName
    ) throws -> T? {
        let valueHolder = try optionalValueHolder(argumentName: argumentName)
        return try valueHolder?.typedValue()
    }
}
