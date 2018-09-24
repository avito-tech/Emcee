import Dispatch
import Foundation
import Models

public final class EventBus {
    private var streams = [EventStream]()
    private let workQueue = DispatchQueue(label: "ru.avito.EventBus.workQueue")
    
    public init() {}
    
    public func add(stream: EventStream) {
        workQueue.async {
            self.streams.append(stream)
        }
    }
    
    public func didObtain(testingResult: TestingResult) {
        forEachStream { stream in
            stream.didObtain(testingResult: testingResult)
        }
    }
    
    public func tearDown() {
        forEachStream { stream in
            stream.tearDown()
        }
    }
    
    private func forEachStream(work: @escaping (EventStream) -> ()) {
        workQueue.async {
            for stream in self.streams {
                work(stream)
            }
        }
    }
}
