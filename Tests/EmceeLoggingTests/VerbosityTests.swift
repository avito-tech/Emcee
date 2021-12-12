import EmceeLogging
import Foundation
import TestHelpers
import XCTest

final class VerbosityTests: XCTestCase {
    func test() {
        assert { Verbosity(rawValue: 000) } equals: { .always }
        assert { Verbosity(rawValue: 100) } equals: { .always }
        assert { Verbosity(rawValue: 199) } equals: { .always }
        
        assert { Verbosity(rawValue: 200) } equals: { .error }
        assert { Verbosity(rawValue: 299) } equals: { .error }
        
        assert { Verbosity(rawValue: 300) } equals: { .warning }
        assert { Verbosity(rawValue: 399) } equals: { .warning }
        
        assert { Verbosity(rawValue: 400) } equals: { .info }
        assert { Verbosity(rawValue: 499) } equals: { .info }
        
        assert { Verbosity(rawValue: 500) } equals: { .debug }
        assert { Verbosity(rawValue: 998) } equals: { .debug }
        
        assert { Verbosity(rawValue: 999) } equals: { .trace }
        assert { Verbosity(rawValue: 123456) } equals: { .trace }
    }
}
