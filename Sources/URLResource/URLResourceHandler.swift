import Foundation
import PathLib

public protocol URLResourceHandler {
    func resource(path: AbsolutePath, forUrl url: URL)
    func failedToGetContents(forUrl url: URL, error: Error)
}
