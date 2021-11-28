import Foundation

public protocol OperatingSystemVersionProvider {
    var operatingSystemVersion: OperatingSystemVersion { get }
}

extension ProcessInfo: OperatingSystemVersionProvider {}

extension OperatingSystemVersion: OperatingSystemVersionProvider {
    public var operatingSystemVersion: OperatingSystemVersion { self }
}
