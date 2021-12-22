import EmceeExtensions
import Foundation
import PlistLib
import TestHelpers
import XCTest

final class PlistEntry_ContainsSameValuesTests: XCTestCase {
    func test___bool() {
        assertTrue {
            PlistEntry.bool(true).containsSameValues(asInPlistEntry: .bool(true))
        }
        assertFalse {
            PlistEntry.bool(true).containsSameValues(asInPlistEntry: .bool(false))
        }
    }
    
    func test___data() {
        assertTrue {
            PlistEntry.data(Data([0x0, 0x1])).containsSameValues(asInPlistEntry: .data(Data([0x0, 0x1])))
        }
        assertFalse {
            PlistEntry.data(Data([0x0, 0x1])).containsSameValues(asInPlistEntry: .data(Data([0x0])))
        }
    }
    
    func test___date() {
        let date = Date()
        
        assertTrue {
            PlistEntry.date(date).containsSameValues(asInPlistEntry: .date(date))
        }
        assertFalse {
            PlistEntry.date(date).containsSameValues(asInPlistEntry: .date(date.addingTimeInterval(5.0)))
        }
    }
    
    func test___number() {
        assertTrue {
            PlistEntry.number(1.0).containsSameValues(asInPlistEntry: .number(1.0))
        }
        assertFalse {
            PlistEntry.number(1.0).containsSameValues(asInPlistEntry: .number(2.0))
        }
    }
    
    func test___string() {
        assertTrue {
            PlistEntry.string("abc").containsSameValues(asInPlistEntry: .string("abc"))
        }
        assertFalse {
            PlistEntry.string("abc").containsSameValues(asInPlistEntry: .string("def"))
        }
    }
    
    func test___array() {
        assertTrue {
            PlistEntry.array([.number(1.0), .bool(true)]).containsSameValues(asInPlistEntry: .array([.number(1.0), .bool(true)]))
        }
        assertFalse {
            PlistEntry.array([.number(2.0), .bool(true)]).containsSameValues(asInPlistEntry: .array([.number(1.0), .bool(false)]))
        }
        
        assertTrue {
            PlistEntry.array(
                [.dict(["key": .string("value"), "other": .string("other")])]
            ).containsSameValues(asInPlistEntry: .array(
                [.dict(["key": .string("value")])]
            ))
        }
        
        assertFalse {
            PlistEntry.array(
                [.dict(["other": .string("value")])]
            ).containsSameValues(asInPlistEntry: .array(
                [.dict(["key": .string("value")])]
            ))
        }
    }
    
    func test___dict() {
        assertTrue {
            PlistEntry.dict(
                ["key": .string("value")]
            ).containsSameValues(asInPlistEntry: PlistEntry.dict(
                ["key": .string("value")]
            ))
        }
        
        assertTrue {
            PlistEntry.dict(
                ["key": .string("value"), "otherKey": .string("other value")]
            ).containsSameValues(asInPlistEntry: PlistEntry.dict(
                ["key": .string("value")]
            ))
        }
        
        assertFalse {
            PlistEntry.dict(
                ["otherKey": .string("other value")]
            ).containsSameValues(asInPlistEntry: PlistEntry.dict(
                ["key": .string("value")]
            ))
        }
        
        assertTrue {
            PlistEntry.dict(
                ["key": .dict(["boolKey": .bool(true), "stringKey": .string("string")])]
            ).containsSameValues(asInPlistEntry: PlistEntry.dict(
                ["key": .dict(["boolKey": .bool(true), "stringKey": .string("string")])]
            ))
        }
    }
    
    func test___heterogeniuos() {
        assertFalse {
            PlistEntry.dict(
                ["key": .string("value")]
            ).containsSameValues(asInPlistEntry: PlistEntry.dict(
                ["key": .bool(true)]
            ))
        }
        
        assertFalse {
            PlistEntry.array(
                [.dict(["key": .string("value"), "other": .string("other")])]
            ).containsSameValues(asInPlistEntry: .array(
                [.dict(["key": .string("otherValue")])]
            ))
        }
    }
}

