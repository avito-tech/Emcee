import Foundation

struct GraphiteMetric {
    let path: [String]
    let value: Double
    let timestamp: Date
    
    private static let pathComponentRegex = try! NSRegularExpression(pattern: "[a-zA-Z0-9-_]*", options: [])
    
    init(path: [String], value: Double, timestamp: Date) throws {
        guard !path.isEmpty else {
            throw GraphiteClientError.incorrectMetricPath(GraphiteMetric.concatenated(path: path))
        }
        guard value.isFinite else {
            throw GraphiteClientError.incorrectValue(value)
        }
        for component in path {
            guard
                !component.isEmpty,
                !component.contains("."),
                GraphiteMetric.pathComponentRegex.numberOfMatches(
                    in: component,
                    options: [],
                    range: NSRange(location: 0, length: component.count)
                ) == 0
                else
            {
                throw GraphiteClientError.incorrectMetricPath(GraphiteMetric.concatenated(path: path))
            }
        }
        
        self.path = path
        self.value = value
        self.timestamp = timestamp
    }
    
    static func concatenated(path: [String]) -> String {
        return path.joined(separator: ".")
    }
}
