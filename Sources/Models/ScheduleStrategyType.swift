import Foundation

public enum ScheduleStrategyType: String, Codable, Equatable {
    case individual = "individual"
    case equallyDivided = "equally_divided"
    case progressive = "progressive"
    
    public static let availableValues: [ScheduleStrategyType] = [.individual, .equallyDivided, .progressive]
    public static let availableRawValues: [String] = availableValues.map { $0.rawValue }
}
