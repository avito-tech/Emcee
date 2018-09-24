import Foundation

public struct DestinationConfiguration: Decodable {
    /** This is an identifier of the DeploymentDestination */
    public let destinationIdentifier: String
    
    /**
     * The value for the number of simulators that can be used on this destination.
     * This overrides the value provided in LocalTestRunConfiguration.
     */
    public let numberOfSimulators: UInt

    public init(destinationIdentifier: String, numberOfSimulators: UInt) {
        self.destinationIdentifier = destinationIdentifier
        self.numberOfSimulators = numberOfSimulators
    }
}
