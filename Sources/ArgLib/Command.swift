import Foundation

public protocol Command {
    var name: String { get }
    var description: String { get }
    var arguments: Arguments { get }
    
    func run(payload: CommandPayload) throws
    func tearDown(timeout: TimeInterval)
}

extension Command {
    public func tearDown(timeout: TimeInterval) { }
}
