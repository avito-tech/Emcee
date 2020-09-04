import Foundation
import Metrics
import Network
import Statsd
import XCTest

final class StatsdMetricHandlerImplTests: XCTestCase {
    func test___handler___doesnt_send_metrics___in_non_ready_states() throws {
        let queue = DispatchQueue(label: "test")
        let states: [NWConnection.State] = [
            .setup,
            .preparing,
            .failed(NWError.posix(.E2BIG)),
            .waiting(NWError.posix(.E2BIG)),
            .cancelled,
        ]
        
        try states.forEach { state in
            let client = FakeStatsdClient(initialState: state)
            let handler = try StatsdMetricHandlerImpl(
                statsdDomain: ["domain"],
                statsdClient: client,
                serialQueue: queue
            )
            
            handler.handle(metric: metric())
            
            queue.sync {}
            XCTAssertTrue(client.sentData.isEmpty)
        }
    }
    
    func test___handler___sends_metric___in_ready_state() throws {
        let queue = DispatchQueue(label: "test")
        let client = FakeStatsdClient(initialState: .ready)
        let handler = try StatsdMetricHandlerImpl(
            statsdDomain: ["domain"],
            statsdClient: client,
            serialQueue: queue
        )
        
        handler.handle(metric: metric())
        
        queue.sync {}
        XCTAssertEqual(
            client.sentData,
            [Data("domain.a.b:1000|ms".utf8)]
        )
    }
    
    func test___handler___buffers_metrics___untill_in_ready_state() throws {
        let queue = DispatchQueue(label: "test")
        let states: [NWConnection.State] = [
            .setup,
            .preparing,
            .waiting(NWError.posix(.E2BIG)),
        ]
        
        try states.forEach { state in
            let client = FakeStatsdClient(initialState: state)
            let handler = try StatsdMetricHandlerImpl(
                statsdDomain: ["domain"],
                statsdClient: client,
                serialQueue: queue
            )
            
            handler.handle(metric: metric())
            client.update(state: .ready)
            
            queue.sync {}
            XCTAssertEqual(
                client.sentData,
                [Data("domain.a.b:1000|ms".utf8)]
            )
        }
    }
    
    private func metric() -> StatsdMetric {
        StatsdMetric(fixedComponents: ["a"], variableComponents: ["b"], value: .time(1))
    }
}
