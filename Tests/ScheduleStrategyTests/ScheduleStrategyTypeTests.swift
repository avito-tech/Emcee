import Foundation
import ScheduleStrategy
import TestHelpers
import XCTest

final class ScheduleStrategyTests: XCTestCase {
    func test___decode_individual() throws {
        let json = Data("""
        {"testSplitterType":{"type":"individual"}}
        """.utf8)

        assert {
            try JSONDecoder().decode(ScheduleStrategy.self, from: json)
        } equals: {
            ScheduleStrategy(testSplitterType: .individual)
        }
    }
    
    func test___decode_progressive() throws {
        let json = Data("""
        {"testSplitterType":{"type":"progressive"}}
        """.utf8)
        
        assert {
            try JSONDecoder().decode(ScheduleStrategy.self, from: json)
        } equals: {
            ScheduleStrategy(testSplitterType: .progressive)
        }
    }
    
    func test___decode_equally_divided() throws {
        let json = Data("""
        {"testSplitterType":{"type":"equallyDivided"}}
        """.utf8)
        
        assert {
            try JSONDecoder().decode(ScheduleStrategy.self, from: json)
        } equals: {
            ScheduleStrategy(testSplitterType: .equallyDivided)
        }
    }
    
    func test___decode_unsplit() throws {
        let json = Data("""
        {"testSplitterType":{"type":"unsplit"}}
        """.utf8)
        
        assert {
            try JSONDecoder().decode(ScheduleStrategy.self, from: json)
        } equals: {
            ScheduleStrategy(testSplitterType: .unsplit)
        }
    }
    
    func test___decode_fixedBucketSize() throws {
        let json = Data("""
        {"testSplitterType":{"type":"fixedBucketSize","size":42}}
        """.utf8)
        
        assert {
            try JSONDecoder().decode(ScheduleStrategy.self, from: json)
        } equals: {
            ScheduleStrategy(testSplitterType: .fixedBucketSize(42))
        }
    }
}
