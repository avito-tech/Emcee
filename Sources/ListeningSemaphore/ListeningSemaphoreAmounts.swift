import Foundation

public protocol ListeningSemaphoreAmounts: Equatable, CustomStringConvertible {
    /// A value with all-zero resources.
    static var zero: Self { get }
    
    /// Caps all resources to the provided maximum value an returns an instance with capped resource values.
    func cappedTo(_ maximumValues: Self) -> Self
    
    /// Returns true if *any* of the resource amounts of this instance is less than the provided resource amounts.
    func containsAnyValueLessThan(_ otherAmounts: Self) -> Bool
    
    /// Returns true if *all* resources of this instance are less than or equal to the provided resource amounts.
    func containsAllValuesLessThanOrEqualTo(_ otherAmounts: Self) -> Bool
    
    /// Returns an instance of a sum of the two provided instances.
    static func +(left: Self, right: Self) -> Self
    
    /// Returns an instance of a subtraction of the two provided instances.
    static func -(left: Self, right: Self) -> Self
}
