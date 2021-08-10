import Foundation
import PathLib

public protocol Demangler {
    func demangle(string: String, bufferSize: Int) throws -> String?
}

public final class LibSwiftDemangler: Demangler {
    private typealias SwiftDemangleFunction = @convention(c) (UnsafePointer<CChar>, UnsafeMutablePointer<CChar>, size_t) -> size_t
    
    enum DemangleError: Error, CustomStringConvertible {
        case dlopenFailed(path: AbsolutePath)
        case dlsymFailed(symbol: String)
        case bufferOverflow(maxSize: Int, actualSize: Int, input: String)
        
        var description: String {
            switch self {
            case .dlopenFailed(let path):
                return "Unable to load dylib at path: \(path)"
            case .dlsymFailed(let symbol):
                return "Unable to locate symbol: \(symbol)"
            case .bufferOverflow(let maxSize, let actualSize, let input):
                return "Unable to demangle into buffer, maximum size of buffer is \(maxSize), but requested size is: \(actualSize), input string: \(input)"
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

    public func demangle(string: String, bufferSize: Int) throws -> String? {
        try demangle(string: string, bufferSize: bufferSize, shouldUseDynamicBufferSize: true)
    }
    
    private func demangle(string: String, bufferSize: Int, shouldUseDynamicBufferSize: Bool) throws -> String? {
        let formattedString = removingExcessLeadingUnderscores(fromString: string)
        let outputString = UnsafeMutablePointer<CChar>.allocate(capacity: bufferSize)
        outputString.initialize(repeating: 0, count: bufferSize)
        defer {
            outputString.deallocate()
        }
        let resultSize = internalDemangleFunction(formattedString, outputString, bufferSize)
        if resultSize > bufferSize {
            if shouldUseDynamicBufferSize {
                return try demangle(
                    string: string,
                    bufferSize: resultSize + 1, // + 1 is for NULL terminator
                    shouldUseDynamicBufferSize: false
                )
            } else {
                /// We use `shouldUseDynamicBufferSize` to avoid a potential recursion,
                /// which can happen in case if `swift_demangle_getDemangledName()` returns different `resultSize` for the same input.
                throw DemangleError.bufferOverflow(maxSize: resultSize, actualSize: resultSize, input: string)
            }
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
