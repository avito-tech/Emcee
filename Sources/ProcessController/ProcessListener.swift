import Foundation

public typealias Unsubscribe = () -> Void
public typealias StdoutListener = (ProcessController, Data, Unsubscribe) -> Void
public typealias StderrListener = (ProcessController, Data, Unsubscribe) -> Void
public typealias SilenceListener = (ProcessController, Unsubscribe) -> Void
