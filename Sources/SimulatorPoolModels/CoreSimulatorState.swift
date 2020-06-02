import Foundation

public enum CoreSimulatorState: Int {
    case creating = 0
    case shutdown = 1
    case booting = 2
    case booted = 3
    case shuttingDown = 4
}
