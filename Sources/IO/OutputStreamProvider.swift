import Foundation

public protocol OutputStreamProvider {
    func createOutputStream() throws -> OutputStream
}
