import Foundation
import PathLib

public protocol Demangler {
    func demangle(string: String) throws -> String?
}

public final class LibSwiftDemangler: Demangler {
    private typealias SwiftDemangleFunction = @convention(c) (UnsafePointer<CChar>, UnsafeMutablePointer<CChar>, size_t) -> size_t
    
    enum DemangleError: Error, CustomStringConvertible {
        case dlopenFailed(path: AbsolutePath)
        case dlsymFailed(symbol: String)
        case bufferOverflow(maxSize: Int, actualSize: Int)
        
        var description: String {
            switch self {
            case .dlopenFailed(let path):
                return "Unable to load dylib at path: \(path)"
            case .dlsymFailed(let symbol):
                return "Unable to locate symbol: \(symbol)"
            case .bufferOverflow(let maxSize, let actualSize):
                return "Unable to demangle into buffer, maximum size of buffer is \(maxSize), but requested size is: \(actualSize)"
            }
        }
    }
    
    private let handle: UnsafeMutableRawPointer
    private let internalDemangleFunction: SwiftDemangleFunction
    private let internalDemangleFunctionName = "swift_demangle_getDemangledName"
    
    public init(libswiftDemanglePath: AbsolutePath) throws {
        guard let handle = dlopen(libswiftDemanglePath.pathString, RTLD_NOW) else {
            throw DemangleError.dlopenFailed(path: libswiftDemanglePath)
        }
        self.handle = handle
        
        guard let address = dlsym(handle, internalDemangleFunctionName) else {
            throw DemangleError.dlsymFailed(symbol: internalDemangleFunctionName)
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
