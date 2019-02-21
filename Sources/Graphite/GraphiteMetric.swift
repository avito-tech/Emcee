import Foundation

struct GraphiteMetric {
    let path: [String]
    let value: Double
    let timestamp: Date
    
    private static let pathComponentRegex = try! NSRegularExpression(pattern: "[a-zA-Z0-9-_]+", options: [])
    
    init(path: [String], value: Double, timestamp: Date) throws {
        guard !path.isEmpty else {
            throw GraphiteClientError.incorrectMetricPath(GraphiteMetric.concatenated(path: path))
        }
        guard value.isFinite else {
            throw GraphiteClientError.incorrectValue(value)
        }
        for component in path {
            let matches = GraphiteMetric.pathComponentRegex.matches(
                in: component,
                options: [],
                range: NSRange(location: 0, length: component.count)
            )
            guard
                matches.count == 1,
                let firstMatch = matches.first,
                firstMatch.range == NSRange(location: 0, length: component.count)
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
