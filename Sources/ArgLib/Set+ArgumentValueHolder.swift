import Foundation

public extension Set where Element == ArgumentValueHolder {
    func value<T: ParsableArgument>(forArgumentWithName argumentName: String) throws -> T {
        guard let valueHolder = first(where: { $0.argumentDescription.name == argumentName }) else {
            throw ArgumentsError.argumentMissing(name: argumentName)
        }
        return try valueHolder.typedValue()
    }
}
