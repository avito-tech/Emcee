import Foundation
import TestDestination

extension TestDestination {
    public func simRuntime() throws -> SimRuntime {
        if let oldStyleSimRuntime = simRuntimeFromRuntimeField() {
            return oldStyleSimRuntime
        }
        
        return SimRuntime(fullyQualifiedId: try value(AppleTestDestinationFields.simRuntime))
    }
    
    public func simDeviceType() throws -> SimDeviceType {
        if let oldStyleSimDeviceType = simDeviceTypeFromDeviceTypeFiled() {
            return oldStyleSimDeviceType
        }
        return SimDeviceType(fullyQualifiedId: try value(AppleTestDestinationFields.simDeviceType))
    }
    
    private func simRuntimeFromRuntimeField() -> SimRuntime? {
        guard let value: String = try? value(AppleTestDestinationFields.runtime) else {
            return nil
        }
        
        return SimRuntime(
            fullyQualifiedId: "com.apple.CoreSimulator.SimRuntime.iOS-" + value
                .replacingOccurrences(of: " ", with: "-")
                .replacingOccurrences(of: ".", with: "-")
        )
    }
    
    private func simDeviceTypeFromDeviceTypeFiled() -> SimDeviceType? {
        guard let value: String = try? value(AppleTestDestinationFields.deviceType) else {
            return nil
        }
        
        return SimDeviceType(
            fullyQualifiedId: "com.apple.CoreSimulator.SimDeviceType." + value
                .replacingOccurrences(of: " ", with: "-")
                .replacingOccurrences(of: ".", with: "-")
                .replacingOccurrences(of: "(", with: "-")
                .replacingOccurrences(of: ")", with: "-")
        )
    }
}
