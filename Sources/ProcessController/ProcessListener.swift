import Foundation

public typealias Unsubscribe = () -> Void
public typealias SignalListener = (ProcessController, Int32, @escaping Unsubscribe) -> Void
public typealias StartListener = (ProcessController, @escaping Unsubscribe) -> Void
public typealias StderrListener = (ProcessController, Data, @escaping Unsubscribe) -> Void
public typealias StdoutListener = (ProcessController, Data, @escaping Unsubscribe) -> Void
public typealias TerminationListener = (ProcessController, @escaping Unsubscribe) -> Void
