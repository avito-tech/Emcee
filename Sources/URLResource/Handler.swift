import Foundation

public protocol Handler {
    func resourceUrl(contentUrl: URL, forUrl url: URL)
    func failedToGetContents(forUrl url: URL, error: Error)
}
