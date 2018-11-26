import Foundation

public protocol Splitter {
    associatedtype Input
    associatedtype SplitInfo
    associatedtype Output
    
    func generate(inputs: [Input], splitInfo: SplitInfo) -> [Output]
}
