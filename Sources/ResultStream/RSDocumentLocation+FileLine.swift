import Foundation
import ResultStreamModels

extension RSDocumentLocation {
    func fileLine() -> (file: String, line: Int) {
        let unknownResult = (file: "unknown", line: 0)
        
        // file:///path/to/file.swift#CharacterRangeLen=0&EndingLineNumber=118&StartingLineNumber=118
        guard
            let url = URL(string: url.stringValue),
            let fragment = url.fragment
        else { return unknownResult }
        
        let pairs: [(String, String)] = fragment
            .split(separator: "&")
            .map { $0.split(separator: "=") }
            .compactMap {
                guard $0.count == 2 else { return nil }
                return (String($0[0]), String($0[1]))
            }
        let dict = [String: String](uniqueKeysWithValues: pairs)
        
        guard let startingLineNumber = dict["StartingLineNumber"], let line = Int(startingLineNumber) else {
            return unknownResult
        }
        
        return (file: url.path, line: line)
    }
}
