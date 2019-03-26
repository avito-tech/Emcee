import Foundation
import Logging

public final class OrphanProcessTracker {
    private final class Coordinates: Codable, Hashable {
        let pid: Int32
        let name: String

        init(pid: Int32, name: String) {
            self.pid = pid
            self.name = name
        }
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(pid)
            hasher.combine(name)
        }
        
        public static func == (left: OrphanProcessTracker.Coordinates, right: OrphanProcessTracker.Coordinates) -> Bool {
            return left.pid == right.pid && left.name == right.name
        }
    }
    
    public static let envName = "AVITO_RUNNER_ORPHAN_PROCESSES_FILE"
    
    public init() {}
    
    public func storeProcessForCleanup(pid: Int32, name: String) {
        whileLocked {
            var contents = load()
            contents.insert(Coordinates(pid: pid, name: name))
            save(contents)
            Logger.debug("Added process \(name):\(pid) to orphan tracking list")
        }
    }
    
    public func removeProcessFromCleanup(pid: Int32, name: String) {
        whileLocked {
            var contents = load()
            if let existingProcessData = contents.remove(Coordinates(pid: pid, name: name)) {
                save(contents)
                Logger.debug("Removed process \(existingProcessData.name):\(existingProcessData.pid) from orphan tracking list")
            } else {
                Logger.debug("Cannot remove process \(name):\(pid) from orphan tracking list, it is not in the list")
            }
        }
    }
    
    public func killAll() {
        whileLocked {
            let coordinates = load()
            for coordinate in coordinates {
                Logger.debug("Killing: \(coordinate.name):\(coordinate.pid)")
                // kills the whole process group
                kill(-coordinate.pid, SIGKILL)
            }
            try? FileManager.default.removeItem(atPath: storagePath)
        }
    }
    
    // MARK: - Private stuff
    
    private let lock = NSRecursiveLock()
    private var encoder = JSONEncoder()
    private var decoder = JSONDecoder()
    private var storagePath: String {
        if let specificPath = ProcessInfo.processInfo.environment[OrphanProcessTracker.envName], !specificPath.isEmpty {
            return specificPath
        } else {
            return ProcessInfo.processInfo.executablePath.appending("_orphans.json.ignored")
        }
    }
    
    private func load() -> Set<Coordinates> {
        guard let contents = try? Data(contentsOf: URL(fileURLWithPath: storagePath)) else { return Set() }
        guard let array = try? decoder.decode([Coordinates].self, from: contents) else { return Set() }
        return Set(array)
    }
    
    private func save(_ coordinates: Set<Coordinates>) {
        guard let data = try? encoder.encode(coordinates) else { return }
        try? data.write(to: URL(fileURLWithPath: storagePath))
    }

    private func whileLocked(work: () -> ()) {
        lock.lock()
        defer { lock.unlock() }
        work()
    }
}
