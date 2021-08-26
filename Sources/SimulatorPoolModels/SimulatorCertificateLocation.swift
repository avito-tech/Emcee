import Foundation
import TypedResourceLocation

public typealias SimulatorCertificateLocation = TypedResourceLocation<SimulatorCertificateLocationType>

public final class SimulatorCertificateLocationType: ResourceLocationType {
    public static let name = "certificate"
}
