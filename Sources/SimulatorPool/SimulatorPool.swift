import DeveloperDirLocator
import Dispatch
import Extensions
import Foundation
import Logging
import Models
import ResourceLocationResolver
import SimulatorPoolModels
import TemporaryStuff
import RunnerModels

/**
 * Every 'borrow' must have a corresponding 'free' call, otherwise the next borrow will throw an error.
 * There is no blocking mechanisms, the assumption is that the callers will use up to numberOfSimulators of threads
 * to borrow and free the simulators.
 */
public protocol SimulatorPool {
    func allocateSimulatorController() throws -> SimulatorController
    func free(simulatorController: SimulatorController)
    func deleteSimulators()
    func shutdownSimulators()
}
