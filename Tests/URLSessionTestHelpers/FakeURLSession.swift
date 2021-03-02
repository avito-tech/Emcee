import Foundation

public final class FakeURLSession: URLSession {
    let session = URLSession.shared
    
    public override init() {
        // this is to mute the warning that init() is deprecated
    }
    
    public var providedDownloadTasks = [FakeDownloadTask]()
    
    public override func downloadTask(with request: URLRequest, completionHandler: @escaping (URL?, URLResponse?, Error?) -> Void) -> URLSessionDownloadTask {
        let task = FakeDownloadTask(
            originalTask: session.downloadTask(with: request, completionHandler: completionHandler),
            completionHandler: completionHandler
        )
        providedDownloadTasks.append(task)
        return task
    }
    
    public var providedDataTasks = [FakeDataTask]()

    public override func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        let task = FakeDataTask(
            originalTask: session.dataTask(with: request, completionHandler: completionHandler),
            completionHandler: completionHandler
        )
        providedDataTasks.append(task)
        return task
    }
}

public class FakeDownloadTask: URLSessionDownloadTask {
    public var originalTask: URLSessionTask
    public var completionHandler: (URL?, URLResponse?, Error?) -> Void
    
    public init(originalTask: URLSessionTask, completionHandler: @escaping (URL?, URLResponse?, Error?) -> Void) {
        self.originalTask = originalTask
        self.completionHandler = completionHandler
    }
    
    @objc private func _onqueue_resume() {
        originalTask.perform(#selector(self._onqueue_resume))
    }
}

public class FakeDataTask: URLSessionDataTask {
    public var originalTask: URLSessionTask
    public var completionHandler: (Data?, URLResponse?, Error?) -> Void
    
    public init(originalTask: URLSessionTask, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
        self.originalTask = originalTask
        self.completionHandler = completionHandler
    }
    
    @objc private func _onqueue_resume() {
        originalTask.perform(#selector(self._onqueue_resume))
    }
}
