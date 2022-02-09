import Foundation
import TestDestination

extension TestDestination {
    public func deviceType() throws -> String {
        return try value(AndroidTestDestinationFields.deviceType)
    }
    
    public func sdkVersion() throws -> Int {
        return try value(AndroidTestDestinationFields.sdkVersion)
    }
}
