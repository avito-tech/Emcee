import Foundation
import SimulatorPoolModels

public enum SimDeviceTypeFixture {
    public static func fixture(_ fqid: String = "fake.simDeviceType") -> SimDeviceType {
        return SimDeviceType(fullyQualifiedId: fqid)
    }
}
