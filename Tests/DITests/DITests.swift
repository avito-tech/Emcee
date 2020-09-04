import DI
import TestHelpers
import XCTest

final class DITests: XCTestCase {
    lazy var di: DI = DIImpl()
    
    func test___registration() throws {
        di.register(String.self, constructor: {"hello"})
        
        let string = try di.get(String.self)
        XCTAssertEqual(string, "hello")
    }
    
    func test___get_without_registration___throws() {
        assertThrows {
            _ = try di.get(String.self)
        }
    }
    
    func test___constructor_is_called_for_each_get() throws {
        var callCount = 0
        
        di.register(String.self, constructor: {
            callCount += 1
            
            return "string"
        })
        
        _ = try di.get(String.self)
        _ = try di.get(String.self)
        
        XCTAssertEqual(callCount, 2)
    }
    
    func test___setting_instance() {
        struct SomeValue: Equatable {
            let uuid = UUID()
        }
        
        let instance = SomeValue()
        di.set(instance)
        
        XCTAssertEqual(try di.get(SomeValue.self), instance)
    }
    
    func test___register_and_get_without_explicit_type() throws {
        di.register { "hello" }
        let string = try di.get() as String
        
        XCTAssertEqual(string, "hello")
    }
    
    func test___registering_multiple_types() {
        di.register(constructor: { 42 })
        di.register(constructor: { 42.24 as Double })
        
        XCTAssertEqual(try di.get() as Int, 42)
        XCTAssertEqual(try di.get() as Double, 42.24)
    }
    
    func test___overwriting_registration() {
        di.register { "hello" }
        di.register { "world" }
        
        XCTAssertEqual(try di.get(String.self), "world")
    }
}
