import Foundation

public protocol URLResourceHandler {
    func resourceUrl(contentUrl: URL, forUrl url: URL)
    func failedToGetContents(forUrl url: URL, error: Error)
}
