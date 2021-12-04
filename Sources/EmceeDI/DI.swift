public protocol DI {
    func get<T>(_ type: T.Type) throws -> T
    func register<T>(_ type: T.Type, constructor: @escaping () -> T)
}

public extension DI {
    func set<T>(_ instance: T) {
        register(T.self, constructor: { return instance })
    }
    
    func set<T>(_ instance: T, for type: T.Type) {
        register(T.self, constructor: { return instance })
    }
    
    func get<T>() throws -> T { try get(T.self) }
    
    func register<T>(constructor: @escaping () -> T) {
        register(T.self, constructor: constructor)
    }
}
