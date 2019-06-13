import Foundation

/// Simulator State Machine provides the actions that should be performed
/// when switching between simulator states.
/// For example if you want to boot a brand new simulator, you are transitioning
/// from state 'absent' to state 'booted'.
/// Machine will provide you actions you need to reach required state: [create, boot].
public final class SimulatorStateMachine {
    public init() {}
    
    public enum State: String, Equatable, CustomStringConvertible {
        case absent
        case created
        case booted
        
        public var description: String {
            return "<\(type(of: self)) \(rawValue)>"
        }
    }
    
    public enum Action: String, Equatable, CustomStringConvertible {
        case create
        case boot
        case shutdown
        case delete
        
        public var resultingState: State {
            switch self {
            case .create:
                return .created
            case .boot:
                return .booted
            case .delete:
                return .absent
            case .shutdown:
                return .created
            }
        }
        
        public var description: String {
            return "<\(type(of: self)) \(rawValue)>"
        }
    }
    
    public func actionsToSwitchStates(
        sourceState: State,
        targetState: State
    ) -> [Action] {
        switch (sourceState, targetState) {
        // Absent -> ...
        case (.absent, .absent):
            return []
        case (.absent, .created):
            return [.create]
        case (.absent, .booted):
            return [.create, .boot]
        // Created -> ...
        case (.created, .created):
            return []
        case (.created, .absent):
            return [.delete]
        case (.created, .booted):
            return [.boot]
        // Booted -> ...
        case (.booted, .absent):
            return [.shutdown, .delete]
        case (.booted, .created):
            return [.shutdown]
        case (.booted, .booted):
            return []
        }
    }
    
    public func actionsToSwitchStates(
        sourceState: State,
        closestStateFrom targetStates: [State]
    ) -> [Action] {
        let actions = targetStates.map {
            actionsToSwitchStates(
                sourceState: sourceState,
                targetState: $0
            )
        }
        let sortedActions = actions.sorted { (leftActions: [Action], rightActions: [Action]) -> Bool in
            return leftActions.count < rightActions.count
        }
        return sortedActions.first ?? []
    }
    
}
