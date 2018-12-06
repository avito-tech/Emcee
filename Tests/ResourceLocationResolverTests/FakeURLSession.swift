import Foundation

public final class FakeURLSession: URLSession {
    let session = URLSession.shared
    
    public var providedDownloadTasks = [URLSessionDownloadTask]()
    
    public override func downloadTask(with request: URLRequest, completionHandler: @escaping (URL?, URLResponse?, Error?) -> Void) -> URLSessionDownloadTask {
        let task = session.downloadTask(with: request, completionHandler: completionHandler)
        providedDownloadTasks.append(task)
        return task
    }
}
