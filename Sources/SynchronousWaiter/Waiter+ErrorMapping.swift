import Foundation
import Logging

public extension Waiter {
    
    /// Maps a `TimeoutError` to other error and throws it instead of throwing original `TimeoutError`.
    /// - Parameters:
    ///   - work: a place where you perform your wait operation which can throw `TimeoutError`.
    ///   - timeoutToErrorTransformation: if timeout happens, this mapper will used to transform `TimeoutError` to other error.
    ///   Any non-`TimeoutError` error won't be transformed.
    /// - Throws: transformed error. Any other error that might be thrown from wait condition block will be thrown unmodified.
    func mapErrorIfTimeout(
        work: (Waiter) throws -> (),
        timeoutToErrorTransformation: (Timeout) -> Error
    ) rethrows {
        do {
            try work(self)
        } catch {
            guard let timeoutError = error as? TimeoutError else {
                throw error
            }
            
            switch timeoutError {
            case .waitTimeout(let timeout):
                let error = timeoutToErrorTransformation(timeout)
                Logger.error("Raising eror after waiting for \(timeout.description) for \(LoggableDuration(timeout.value)): \(error)")
                throw error
            }
        }
    }
}
