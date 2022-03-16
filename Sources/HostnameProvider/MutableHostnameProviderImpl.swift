import AtomicModels
import Foundation

public final class MutableHostnameProviderImpl: MutableHostnameProvider {
    private let value: AtomicValue<String>
    
    public init(hostname: String) {
        self.value = AtomicValue(hostname)
    }
    
    public var hostname: String {
        value.currentValue()
    }
    
    public func set(hostname: String) {
        value.set(hostname)
    }
}
