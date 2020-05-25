import PlistLib
import TestHelpers
import XCTest

final class PlistEntryTests: XCTestCase {
    func test___accessing_entries_in_array() {
        let entry = PlistEntry.array([.string("hello")])
        XCTAssertEqual(
            try entry.entry(atIndex: 0),
            .string("hello")
        )
    }
    
    func test___accessing_entries_in_dict() {
        let entry = PlistEntry.dict(["key": .string("hello")])
        
        XCTAssertEqual(
            try entry.entry(forKey: "key"),
            .string("hello")
        )
    }
    
    func test___string() {
        let entry = PlistEntry.string("hello")
        XCTAssertEqual(
            try entry.stringValue(),
            "hello"
        )
    }
    
    func test___bool() {
        let entry = PlistEntry.bool(true)
        XCTAssertEqual(
            try entry.boolValue(),
            true
        )
    }
    
    func test___date() {
        let date = Date()
        
        let entry = PlistEntry.date(date)
        XCTAssertEqual(
            try entry.dateValue(),
            date
        )
    }
    
    func test___data() {
        let data = Data([0x11, 0x22])
        
        let entry = PlistEntry.data(data)
        XCTAssertEqual(
            try entry.dataValue(),
            data
        )
    }
    
    func test___accessing_incorrect_value() {
        let entry = PlistEntry.string("hello")
        
        assertThrows { try entry.dateValue() }
    }
    
    func test___accesing_via_typed_functions() {
        let entry = PlistEntry.dict([
            "root": .array([
                .string("hello"),
                .array([.data(Data([0xFF]))])
            ])
        ])
        
        XCTAssertEqual(
            try entry.entry(forKey: "root").entry(atIndex: 1).entry(atIndex: 0).dataValue(),
            Data([0xFF])
        )
    }
    
    func test___accessing_bool_using_number___throws() {
        let entry = PlistEntry.bool(true)
        assertThrows { _ = try entry.numberValue() }
    }
    
    func test___accessing_number_using_bool___throws() {
        let entry = PlistEntry.number(3.14)
        assertThrows { _ = try entry.boolValue() }
    }
}
