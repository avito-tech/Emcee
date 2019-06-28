import Foundation
import JSONStream
import XCTest

class JSONReaderTests: XCTestCase {
    
    var eventStream = FakeEventStream()
    override func setUp() {
        eventStream = FakeEventStream()
    }
    
    func testEmptyObject() throws {
        let jsonStream = FakeJSONStream(string: "{}")
        let reader = JSONReader(inputStream: jsonStream, eventStream: eventStream)
        try reader.start()
        
        XCTAssertTrue(eventStream.allObjects[0].count == 0)
    }
    
    func testEmptyArray() throws {
        let jsonStream = FakeJSONStream(string: "[]")
        let reader = JSONReader(inputStream: jsonStream, eventStream: eventStream)
        try reader.start()
        
        XCTAssertTrue(eventStream.allArrays[0].count == 0)
    }
    
    func testSimpleObject() throws {
        let jsonStream = FakeJSONStream(string: "{\"the key\": \"the value\"}")
        let reader = JSONReader(inputStream: jsonStream, eventStream: eventStream)
        try reader.start()
        
        XCTAssertEqual(eventStream.allObjects[0], ["the key": "the value"])
    }
    
    func testSimpleArrayWithString() throws {
        let jsonStream = FakeJSONStream(string: "[\"value\"]")
        let reader = JSONReader(inputStream: jsonStream, eventStream: eventStream)
        try reader.start()
        
        XCTAssertEqual(eventStream.allArrays[0], ["value"])
    }
    
    func testBrokenArrayWithSingleComma() throws {
        let jsonStream = FakeJSONStream(string: "[\"value\",]")
        let reader = JSONReader(inputStream: jsonStream, eventStream: eventStream)
        XCTAssertThrowsError(try reader.start())
    }
    
    func testBrokenArrayWithDoubleComma() throws {
        let jsonStream = FakeJSONStream(string: "[\"value\",,]")
        let reader = JSONReader(inputStream: jsonStream, eventStream: eventStream)
        XCTAssertThrowsError(try reader.start())
    }
    
    func testBrokenArrayWithOnlyComma() throws {
        let jsonStream = FakeJSONStream(string: "[,]")
        let reader = JSONReader(inputStream: jsonStream, eventStream: eventStream)
        XCTAssertThrowsError(try reader.start())
    }
    
    func testSimpleArrayWithMultipleStrings() throws {
        let jsonStream = FakeJSONStream(string: "[\"obj1\",\"obj2\",\"obj3\"]")
        let reader = JSONReader(inputStream: jsonStream, eventStream: eventStream)
        try reader.start()
        
        XCTAssertEqual(eventStream.allArrays[0], ["obj1","obj2","obj3"])
    }
    
    func testKeyToObject() throws {
        let jsonStream = FakeJSONStream(string: "{\"the key\": {\"subobject\": \"subvalue\"}}")
        let reader = JSONReader(inputStream: jsonStream, eventStream: eventStream)
        try reader.start()
        
        XCTAssertEqual(eventStream.allObjects[0], ["the key": ["subobject": "subvalue"]])
    }
    
    func testMultipleKeys() throws {
        let jsonStream = FakeJSONStream(string: "{\"one\": \"1\", \"two\": \"2\"}")
        let reader = JSONReader(inputStream: jsonStream, eventStream: eventStream)
        try reader.start()
        
        XCTAssertEqual(eventStream.allObjects[0], ["one": "1", "two": "2"])
    }
    
    func testMultipleCommasInObject() throws {
        let jsonStream = FakeJSONStream(string: "{\"one\": \"1\",, \"two\": \"2\"}")
        let reader = JSONReader(inputStream: jsonStream, eventStream: eventStream)
        XCTAssertThrowsError(try reader.start())
    }
    
    func testObjectWithTailingComma() throws {
        let jsonStream = FakeJSONStream(string: "{\"one\": \"1\",}")
        let reader = JSONReader(inputStream: jsonStream, eventStream: eventStream)
        XCTAssertThrowsError(try reader.start())
    }
    
    func testEmptyValue() throws {
        let jsonStream = FakeJSONStream(string: "{\"key\": \"\"}")
        let reader = JSONReader(inputStream: jsonStream, eventStream: eventStream)
        try reader.start()
        
        XCTAssertEqual(eventStream.allObjects[0], ["key": ""])
    }
    
    func testTwoObjectsInStream() throws {
        let jsonStream = FakeJSONStream(string: "{\"key1\": \"value1\"}{\"key2\": \"value2\"}")
        let reader = JSONReader(inputStream: jsonStream, eventStream: eventStream)
        try reader.start()
        XCTAssertEqual(eventStream.all.count, 2)
        XCTAssertEqual(eventStream.allObjects[0], ["key1": "value1"])
        XCTAssertEqual(eventStream.allObjects[1], ["key2": "value2"])
    }
    
    func testArrayWithNull() throws {
        let jsonStream = FakeJSONStream(string: "[null]")
        let reader = JSONReader(inputStream: jsonStream, eventStream: eventStream)
        try reader.start()
        
        XCTAssertEqual(eventStream.allArrays[0], [NSNull()])
    }
    
    func testObjectWithNullValue() throws {
        let jsonStream = FakeJSONStream(string: "{\"key\": null}")
        let reader = JSONReader(inputStream: jsonStream, eventStream: eventStream)
        try reader.start()
        
        XCTAssertEqual(eventStream.allObjects[0], ["key": NSNull()])
    }
    
    func testObjectWithNullKeyFails() throws {
        let jsonStream = FakeJSONStream(string: "{null: \"value\"}")
        let reader = JSONReader(inputStream: jsonStream, eventStream: eventStream)
        XCTAssertThrowsError(try reader.start())
    }
    
    func testArrayWithTrue() throws {
        let jsonStream = FakeJSONStream(string: "[true]")
        let reader = JSONReader(inputStream: jsonStream, eventStream: eventStream)
        try reader.start()
        
        XCTAssertEqual(eventStream.allArrays[0], [true])
    }
    
    func testObjectWithTrueValue() throws {
        let jsonStream = FakeJSONStream(string: "{\"key\": true}")
        let reader = JSONReader(inputStream: jsonStream, eventStream: eventStream)
        try reader.start()
        
        XCTAssertEqual(eventStream.allObjects[0], ["key": true])
    }
    
    func testObjectWithTrueKeyFails() throws {
        let jsonStream = FakeJSONStream(string: "{true: \"value\"}")
        let reader = JSONReader(inputStream: jsonStream, eventStream: eventStream)
        XCTAssertThrowsError(try reader.start())
    }
    
    func testArrayWithFalse() throws {
        let jsonStream = FakeJSONStream(string: "[false]")
        let reader = JSONReader(inputStream: jsonStream, eventStream: eventStream)
        try reader.start()
        
        XCTAssertEqual(eventStream.allArrays[0], [false])
    }
    
    func testObjectWithFalseValue() throws {
        let jsonStream = FakeJSONStream(string: "{\"key\": false}")
        let reader = JSONReader(inputStream: jsonStream, eventStream: eventStream)
        try reader.start()
        
        XCTAssertEqual(eventStream.allObjects[0], ["key": false])
    }
    
    func testObjectWithFalseKeyFails() throws {
        let jsonStream = FakeJSONStream(string: "{false: \"value\"}")
        let reader = JSONReader(inputStream: jsonStream, eventStream: eventStream)
        XCTAssertThrowsError(try reader.start())
    }
    
    func testArrayWithNullTrueFalseObjectAndString() throws {
        let jsonStream = FakeJSONStream(string: "[null, true, false, {\"key\": \"value\"}, \"string\"]")
        let reader = JSONReader(inputStream: jsonStream, eventStream: eventStream)
        try reader.start()
        
        XCTAssertEqual(eventStream.allArrays[0], [NSNull(), true, false, ["key": "value"], "string"])
    }
    
    func testArraySingleNumber() throws {
        let jsonStream = FakeJSONStream(string: "[42]")
        let reader = JSONReader(inputStream: jsonStream, eventStream: eventStream)
        try reader.start()
        
        XCTAssertEqual(eventStream.allArrays[0], [42])
    }
    
    func testArraySingleNegativeNumber() throws {
        let jsonStream = FakeJSONStream(string: "[-42]")
        let reader = JSONReader(inputStream: jsonStream, eventStream: eventStream)
        try reader.start()
        
        XCTAssertEqual(eventStream.allArrays[0], [-42])
    }
    
    func testArrayTwoNumbers() throws {
        let jsonStream = FakeJSONStream(string: "[-42, 42]")
        let reader = JSONReader(inputStream: jsonStream, eventStream: eventStream)
        try reader.start()
        
        XCTAssertEqual(eventStream.allArrays[0], [-42, 42])
    }
    
    func testArrayWithExponentialNumbers() throws {
        let jsonStream = FakeJSONStream(string: "[-42e-3, 42e+3]")
        let reader = JSONReader(inputStream: jsonStream, eventStream: eventStream)
        try reader.start()
        
        XCTAssertEqual(eventStream.allArrays[0], [-0.042, 42000])
    }
    
    func testArrayWithNegativeDoubleExponentialNumber() throws {
        let jsonStream = FakeJSONStream(string: "[-14318475.1248132e7]")
        let reader = JSONReader(inputStream: jsonStream, eventStream: eventStream)
        try reader.start()
        
        XCTAssertEqual(eventStream.allArrays[0], [-143184751248132])
    }
    
    func testObjectWithSingleNumberValue() throws {
        let jsonStream = FakeJSONStream(string: "{\"key\": 42}")
        let reader = JSONReader(inputStream: jsonStream, eventStream: eventStream)
        try reader.start()
        
        XCTAssertEqual(eventStream.allObjects[0], ["key": 42])
    }
    
    func testArrayWithIncorrectNumber() throws {
        let jsonStream = FakeJSONStream(string: "[-12ABA]")
        let reader = JSONReader(inputStream: jsonStream, eventStream: eventStream)
        XCTAssertThrowsError(try reader.start())
    }
    
    func testObjectWithIncorrectNumberValue() throws {
        let jsonStream = FakeJSONStream(string: "{\"key\": -12.bad-number}")
        let reader = JSONReader(inputStream: jsonStream, eventStream: eventStream)
        XCTAssertThrowsError(try reader.start())
    }
    
    func testObjectWithArrayValue() throws {
        let jsonStream = FakeJSONStream(string: "{\"key\":[\"obj\"]}")
        let reader = JSONReader(inputStream: jsonStream, eventStream: eventStream)
        try reader.start()
        
        XCTAssertEqual(eventStream.all.count, 1)
        XCTAssertEqual(eventStream.allObjects[0], ["key": ["obj"]])
    }
    
    func testArrayWithArray() throws {
        let jsonStream = FakeJSONStream(string: "[[\"obj\"]]")
        let reader = JSONReader(inputStream: jsonStream, eventStream: eventStream)
        try reader.start()
        
        XCTAssertEqual(eventStream.all.count, 1)
        XCTAssertEqual(eventStream.allArrays[0], [["obj"]])
    }
    
    func testArrayWithObject() throws {
        let jsonStream = FakeJSONStream(string: "[{\"key\":\"value\"}]")
        let reader = JSONReader(inputStream: jsonStream, eventStream: eventStream)
        try reader.start()
        
        XCTAssertEqual(eventStream.all.count, 1)
        XCTAssertEqual(eventStream.allArrays[0], [["key": "value"]])
    }

    func testComplexStream() throws {
        let dict: [String : Any] = [
            "key": [true, false, NSNull()],
            "second_key": [
                "subobject_key1": 12,
                "subobject_key2": "string with spaces"
            ]
            ]
        let array: [Any] = ["string!", dict, false, 12e2]

        let firstObjectString = String(data: try JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted]), encoding: .utf8)!
        let secondObjectString = String(data: try JSONSerialization.data(withJSONObject: array, options: [.prettyPrinted]), encoding: .utf8)!

        let jsonStream = FakeJSONStream(string: firstObjectString + "\n" + secondObjectString)
        let reader = JSONReader(inputStream: jsonStream, eventStream: eventStream)
        try reader.start()

        XCTAssertEqual(eventStream.all.count, 2)
        XCTAssertEqual(eventStream.allObjects[0], dict as NSDictionary)
        XCTAssertEqual(eventStream.allArrays[0], array as NSArray)
    }
    
    func testEventStreamGetsScalars() throws {
        let jsonStream = FakeJSONStream(string: "[[\"obj\"]]")
        let reader = JSONReader(inputStream: jsonStream, eventStream: eventStream)
        try reader.start()
        
        XCTAssertEqual(eventStream.allScalars.count, 1)
        var string = String()
        string.unicodeScalars.append(contentsOf: eventStream.allScalars[0])
        XCTAssertEqual(string, "[[\"obj\"]]")
    }
}
