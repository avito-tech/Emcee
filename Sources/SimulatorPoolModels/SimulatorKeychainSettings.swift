public struct SimulatorKeychainSettings: Codable, CustomStringConvertible, Hashable {
    public let rootCerts: [SimulatorCertificateLocation]
    
    public init(rootCerts: [SimulatorCertificateLocation]) {
        self.rootCerts = rootCerts
    }
    
    public var description: String {
        return "<\(type(of: self)) rootCerts: \(rootCerts)>"
    }
}
