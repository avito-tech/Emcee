import Foundation
import ListeningSemaphore

final class ResourceAmountsDouble: ListeningSemaphoreAmounts {
    static var zero: ResourceAmountsDouble = ResourceAmountsDouble(firstResource: 0, secondResource: 0)
    
    public let firstResource: Int
    public let secondResource: Int
    
    public init(firstResource: Int, secondResource: Int) {
        self.firstResource = firstResource
        self.secondResource = secondResource
    }
    
    public static func of(firstResource: Int = 0, secondResource: Int = 0) -> ResourceAmountsDouble {
        return ResourceAmountsDouble(
            firstResource: firstResource,
            secondResource: secondResource
        )
    }
    
    func cappedTo(_ maximumValues: ResourceAmountsDouble) -> ResourceAmountsDouble {
        return ResourceAmountsDouble(
            firstResource: min(firstResource, maximumValues.firstResource),
            secondResource: min(secondResource, maximumValues.secondResource)
        )
    }
    
    func containsAnyValueLessThan(_ otherAmounts: ResourceAmountsDouble) -> Bool {
        return firstResource < otherAmounts.firstResource
            || secondResource < otherAmounts.secondResource
    }
    
    static func == (left: ResourceAmountsDouble, right: ResourceAmountsDouble) -> Bool {
        return left.firstResource == right.firstResource
            && left.secondResource == right.secondResource
    }
    
    public func containsAllValuesLessThanOrEqualTo(_ otherAmounts: ResourceAmountsDouble) -> Bool {
        return firstResource <= otherAmounts.firstResource
            && secondResource <= otherAmounts.secondResource
    }
    
    static func +(left: ResourceAmountsDouble, right: ResourceAmountsDouble) -> ResourceAmountsDouble {
        return ResourceAmountsDouble(
            firstResource: left.firstResource + right.firstResource,
            secondResource: left.secondResource + right.secondResource
        )
    }
    
    static func -(left: ResourceAmountsDouble, right: ResourceAmountsDouble) -> ResourceAmountsDouble {
        return ResourceAmountsDouble(
            firstResource: left.firstResource - right.firstResource,
            secondResource: left.secondResource - right.secondResource
        )
    }
    
    var description: String {
        return "ResourceAmountsDouble: firstResource=\(firstResource) secondResource=\(secondResource)"
    }
}
