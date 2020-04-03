import Foundation
import PathLib

public protocol Demangler {
    func demangle(string: String) throws -> String?
}

public final class LibSwiftDemangler: Demangler {
    private typealias SwiftDemangleFunction = @convention(c) (UnsafePointer<CChar>, UnsafeMutablePointer<CChar>, size_t) -> size_t
    
    enum DemangleError: Error {
        case dlopenFailed
        case dlsymFailed
        case bufferOverflow(maxSize: Int, actualSize: Int)
    }
    
    private let handle: UnsafeMutableRawPointer
    private let internalDemangleFunction: SwiftDemangleFunction
    
    public init(libswiftDemanglePath: AbsolutePath) throws {
        guard let handle = dlopen(libswiftDemanglePath.pathString, RTLD_NOW) else {
            throw DemangleError.dlopenFailed
        }
        self.handle = handle
        
        guard let address = dlsym(handle, "swift_demangle_getDemangledName") else {
            throw DemangleError.dlsymFailed
        }
        internalDemangleFunction = unsafeBitCast(address, to: SwiftDemangleFunction.self)
    }
    
    private let kBufferSize = 1024

    public func demangle(string: String) throws -> String? {
        let formattedString = removingExcessLeadingUnderscores(fromString: string)
        let outputString = UnsafeMutablePointer<CChar>.allocate(capacity: kBufferSize)
        let resultSize = internalDemangleFunction(formattedString, outputString, kBufferSize)
        if resultSize > kBufferSize {
            throw DemangleError.bufferOverflow(maxSize: kBufferSize, actualSize: resultSize)
        }

        return String(cString: outputString, encoding: .utf8)
    }

    private func removingExcessLeadingUnderscores(fromString string: String) -> String {
        if string.hasPrefix("__T") {
            return String(string.dropFirst())
        }
        return string
    }

    deinit {
        dlclose(handle)
    }
}
