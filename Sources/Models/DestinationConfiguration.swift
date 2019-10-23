import Foundation

public struct DestinationConfiguration: Decodable {
    /// This is an identifier of the DeploymentDestination
    public let destinationIdentifier: WorkerId
    
    /// The value for the number of simulators that can be used on this destination.
    public let numberOfSimulators: UInt

    public init(destinationIdentifier: WorkerId, numberOfSimulators: UInt) {
        self.destinationIdentifier = destinationIdentifier
        self.numberOfSimulators = numberOfSimulators
    }
}
