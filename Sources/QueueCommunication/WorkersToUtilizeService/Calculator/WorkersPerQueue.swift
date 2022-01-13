import QueueModels

public final class WorkersPerQueue: Hashable, CustomStringConvertible, ExpressibleByDictionaryLiteral {
    var workersByQueueInfo: [QueueInfo: Set<WorkerId>]

    public init(_ workersByQueueInfo: [QueueInfo: Set<WorkerId>] = [:]) {
        self.workersByQueueInfo = workersByQueueInfo
    }

    public subscript(queueIndo: QueueInfo) -> Set<WorkerId>? {
        get {
            workersByQueueInfo[queueIndo]
        }
        set(newValue) {
            workersByQueueInfo[queueIndo] = newValue
        }
    }
    
    public var description: String {
        workersByQueueInfo
            .map { keyValue in
                (keyValue.key, keyValue.value.map(\.value).sorted())
            }
            .sorted { left, right in
                left.0 < right.0
            }
            .map { keyValue in
                "\(keyValue.0): \(keyValue.1)"
            }.joined(separator: "; ")
    }
    
    public func sorted(
        by sorter: (QueueInfo, QueueInfo) -> Bool
    ) -> [(queueInfo: QueueInfo, workerIds: Set<WorkerId>)] {
        workersByQueueInfo.sorted { l, r in
            sorter(l.key, r.key)
        }.map {
            (queueInfo: $0.key, workerIds: $0.value)
        }
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(workersByQueueInfo)
    }
    
    public static func == (lhs: WorkersPerQueue, rhs: WorkersPerQueue) -> Bool {
        lhs.workersByQueueInfo == rhs.workersByQueueInfo
    }
    
    public typealias Key = QueueInfo
    public typealias Value = Set<WorkerId>
    
    public init(dictionaryLiteral elements: (QueueInfo, Set<WorkerId>)...) {
        workersByQueueInfo = Dictionary(uniqueKeysWithValues: elements)
    }
}
