import Foundation
import PlistLib
import TestHelpers
import XCTest

final class PlistTests: XCTestCase {
    private lazy var plistStringContents = """
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
        <key>key</key>
        <string>value</string>
    </dict>
    </plist>\n
    """
    
    func test___encoding_to_data() throws {
        let plist = Plist(
            rootPlistEntry: .dict([
                "key": .string("value")
            ])
        )
        let plistData = try plist.data(format: .xml)
        
        guard let string = String(data: plistData, encoding: .utf8) else {
            failTest("Failed to convert data to string")
        }
        
        XCTAssertEqual(
            string.replacingOccurrences(of: "\t", with: "    "),
            plistStringContents
        )
    }
    
    func test___parsing_data() throws {
        guard let plistData = plistStringContents.data(using: .utf8) else {
            failTest("Failed to convert string to data")
        }
        
        let plist = try Plist.create(fromData: plistData)
        XCTAssertEqual(
            plist.root,
            RootPlistEntry.dict(["key": .string("value")])
        )
    }
    
    func test___root_dict_object() throws {
        let plist = Plist(rootPlistEntry: .dict(["key": .string("value")]))
        XCTAssertEqual(
            plist.rootObject() as? NSDictionary,
            ["key": "value"]
        )
    }
    
    func test___to_typed_dict___when_dict_is_empty___throws() throws {
        let entry = PlistEntry.dict(["key": nil])
        assertThrows {
            _ = try entry.toTypedDict(String.self)
        }
    }
    
    func test___to_typed_dict___when_dict_is_not_empty___does_not_throw() throws {
        let entry = PlistEntry.dict(["key": .string("value")])
        XCTAssertEqual(
            try entry.toTypedDict(String.self),
            ["key": "value"]
        )
    }
    
    func test___to_typed_dict___when_dict_is_heterogeneous___throws() throws {
        let entry = PlistEntry.dict(["key": .string("value"), "key2": .bool(false)])
        assertThrows { _ = try entry.toTypedDict(String.self) }
        assertThrows { _ = try entry.toTypedDict(Bool.self) }
    }
    
    func test___root_array_object() throws {
        let plist = Plist(rootPlistEntry: .array([.string("hello")]))
        XCTAssertEqual(
            plist.rootObject() as? NSArray,
            ["hello"]
        )
    }
    
    func test___to_typed_array___when_array_is_empty___throws() throws {
        let entry = PlistEntry.array([nil])
        assertThrows {
            _ = try entry.toTypedArray(String.self)
        }
    }
    
    func test___to_typed_array___when_array_is_not_empty___does_not_throw() throws {
        let entry = PlistEntry.array([.string("hello")])
        XCTAssertEqual(
            try entry.toTypedArray(String.self),
            ["hello"]
        )
    }
    
    func test___to_typed_array___when_array_is_heterogeneous___throws() throws {
        let entry = PlistEntry.array([.string("hello"), .bool(false)])
        assertThrows { _ = try entry.toTypedArray(String.self) }
        assertThrows { _ = try entry.toTypedArray(Bool.self) }
    }
    
    func test___parsing_bool_value() throws {
        let plist = Plist(rootPlistEntry: .array([.bool(true)]))
        let parsedPlist = try Plist.create(fromData: try plist.data(format: .xml))
        
        XCTAssertEqual(
            plist.root,
            parsedPlist.root
        )
    }
    
    func test___parsing_number_value() throws {
        let plist = Plist(rootPlistEntry: .array([.number(123)]))
        let parsedPlist = try Plist.create(fromData: try plist.data(format: .xml))
        
        XCTAssertEqual(
            plist.root,
            parsedPlist.root
        )
    }
    
    func test___parsing_data_value() throws {
        let plist = Plist(rootPlistEntry: .array([.data(Data([0x42]))]))
        let parsedPlist = try Plist.create(fromData: try plist.data(format: .xml))
        
        XCTAssertEqual(
            plist.root,
            parsedPlist.root
        )
    }
    
    func test___parsing_date_value() throws {
        let plist = Plist(rootPlistEntry: .array([.date(Date(timeIntervalSinceReferenceDate: 424242))]))
        let parsedPlist = try Plist.create(fromData: try plist.data(format: .xml))
        
        XCTAssertEqual(
            plist.root,
            parsedPlist.root
        )
    }
}
