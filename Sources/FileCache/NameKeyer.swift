import Foundation

public protocol NameKeyer {
    func key(forName name: String) throws -> String
}
