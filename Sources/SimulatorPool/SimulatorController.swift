import Foundation
import Models

public protocol SimulatorController {
    func bootedSimulator() throws -> Simulator
    func shutdownSimulator() throws
    func deleteSimulator() throws
}
