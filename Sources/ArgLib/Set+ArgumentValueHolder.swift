import Foundation

public extension Set where Element == ArgumentValueHolder {
    func valueHolder(forArgumentWithName argumentName: String) throws -> ArgumentValueHolder {
        guard let valueHolder = first(where: { $0.argumentDescription.name == argumentName }) else {
            throw ArgumentsError.argumentMissing(name: argumentName)
        }
        return valueHolder
    }

    func value<T: ParsableArgument>(forArgumentWithName argumentName: String) throws -> T {
        let valueHolder = try self.valueHolder(forArgumentWithName: argumentName)
        return try valueHolder.typedValue()
    }

    func stringValue(forArgumentWithName argumentName: String) throws -> String {
        let valueHolder = try self.valueHolder(forArgumentWithName: argumentName)
        return valueHolder.stringValue
    }
}
