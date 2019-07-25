import Foundation

public enum ScheduleStrategyType: String, Codable, Equatable, CaseIterable {
    case individual = "individual"
    case equallyDivided = "equally_divided"
    case progressive = "progressive"
    
    public static let availableRawValues: [String] = allCases.map { $0.rawValue }
}
