import Foundation

/**
 * JSON reader that utilizes JSONStream to parse the JSON stream on the fly.
 */
public final class JSONReader {
    let inputStream: JSONStream
    let eventStream: JSONReaderEventStream
    var context = [ParsingContext.root]
    
    let anyCharacterSet = CharacterSet([]).inverted
    let numberChars = CharacterSet(charactersIn: "-1234567890")
    let whiteCharacters = CharacterSet.whitespacesAndNewlines
    public private(set) var collectedScalars = [Unicode.Scalar]()
    
    enum `Error`: Swift.Error {
        case unexpectedCharacter(Unicode.Scalar)
        case unexpectedCharacters([Unicode.Scalar], expected: [Unicode.Scalar])
        case streamHasNoData
        case streamEndedAtRootContext
        case unexpectedEndOfStream
        case invalidData
        case invalidNumberValue(String)
        case arrayCannotHaveKeys(parent: ParsingContext, child: ParsingContext)
        case objectMustHaveKey(parent: ParsingContext, child: ParsingContext)
        case unhandledContextCombination(parent: ParsingContext, child: ParsingContext)
    }
    
    public init(inputStream: JSONStream, eventStream: JSONReaderEventStream) {
        self.inputStream = inputStream
        self.eventStream = eventStream
    }
    
    public func start() throws {
        try readAndThrowErrorOnFailure()
    }
    
    private func readAndThrowErrorOnFailure() throws {
        do {
            try readRecursively()
        } catch {
            if let readerError = error as? Error, case Error.streamEndedAtRootContext = readerError {
                return
            } else {
                throw error
            }
        }
    }
    
    private func readRecursively() throws {
        while true {
            switch currentContext {
            case .root:
                try validateRootContext()
            case .inObject(let key, let storage):
                try validateObjectContext(key, storage)
            case .inArray(let key, let storage):
                try validateArrayContext(key, storage)
            case .inKey(let keyStorage):
                try validateKeyContext(keyStorage)
            case .inValue(let key):
                try validateValueForKeyContext(key)
            case .inStringValue(_, let storage):
                try validateStringContext(storage)
            case .inStringObject(let storage):
                try validateStringContext(storage)
            case .inNullValue(_):
                try validateNullContext()
            case .inTrueValue(_):
                try validateTrueContext()
            case .inFalseValue(_):
                try validateFalseContext()
            case .inNumericValue(let key, let storage):
                try validateNumericContext(key, storage)
            }
        }
    }
    
    private func validateRootContext() throws {
        let readResult = read(untilAnyCharacterFrom: anyCharacterSet, ignoreCharacters: whiteCharacters)
        guard let scalar = readResult.matchingScalar else { throw Error.streamEndedAtRootContext }
        
        switch scalar {
        case "[":
            pushContext(.inArray(key: nil, storage: NSMutableArray()))
        case "{":
            pushContext(.inObject(key: nil, storage: NSMutableDictionary()))
        default:
            throw Error.unexpectedCharacter(scalar)
        }
    }
    
    private func validateObjectContext(
        _ key: String?,
        _ storage: NSMutableDictionary,
        expectingAnotherKeyValue: Bool = false) throws {
        // {  "key": "value"}, {"key": []}, {"key": {}  }
        //  ^
        let readResult = read(untilAnyCharacterFrom: anyCharacterSet, ignoreCharacters: whiteCharacters)
        guard let scalar = readResult.matchingScalar else { throw Error.streamHasNoData }
        
        switch scalar {
        case "}":
            if !expectingAnotherKeyValue {
                try popContext()
            } else {
                throw Error.unexpectedCharacter(scalar)
            }
        case "\"":
            pushContext(.inKey(NSMutableString()))
        case ",":
            if storage.count == 0 || expectingAnotherKeyValue {
                throw Error.unexpectedCharacter(scalar)
            } 
            try validateObjectContext(key, storage, expectingAnotherKeyValue: true)
        default:
            throw Error.unexpectedCharacter(scalar)
        }
    }
    
    private func validateKeyContext(_ keyStorage: NSMutableString) throws {
        // "key" :
        //  ^ we're here
        var readResult = read(untilAnyCharacterFrom: CharacterSet(["\""]))
        guard readResult.matchingScalar == "\"" else { throw Error.streamHasNoData }
        var key = ""
        key.unicodeScalars.append(contentsOf: readResult.passedScalars)
        keyStorage.setString(key)
        
        // "key" :
        //      ^ we're here
        readResult = read(untilAnyCharacterFrom: CharacterSet([":"]), ignoreCharacters: whiteCharacters)
        guard readResult.passedScalars.isEmpty else { throw Error.unexpectedCharacter(readResult.passedScalars[0]) }
        guard let scalar = readResult.matchingScalar else { throw Error.streamHasNoData }
        guard scalar == ":" else { throw Error.unexpectedCharacter(scalar) }
        
        try popContext()
        pushContext(.inValue(key: key))
    }
    
    private func validateValueForKeyContext(_ key: String) throws {
        // "key":  _____
        //       ^ we're here
        let readResult = read(untilAnyCharacterFrom: anyCharacterSet, ignoreCharacters: whiteCharacters)
        guard let scalar = readResult.matchingScalar else { throw Error.streamHasNoData }
        
        try popContext()
        
        switch scalar {
        case "[":
            pushContext(.inArray(key: key, storage: NSMutableArray()))
        case "{":
            pushContext(.inObject(key: key, storage: NSMutableDictionary()))
        case "\"":
            pushContext(.inStringValue(key: key, storage: NSMutableString()))
        case "n":
            pushContext(.inNullValue(key: key))
        case "t":
            pushContext(.inTrueValue(key: key))
        case "f":
            pushContext(.inFalseValue(key: key))
        case numberChars.contains(scalar) ? scalar : nil:
            pushContext(.inNumericValue(key: key, storage: NumericStorage(String(scalar))))
        default:
            throw Error.unexpectedCharacter(scalar)
        }
    }
    
    private func validateStringContext(_ storage: NSMutableString) throws {
        // "some string"
        //  ^ we're here
        var string = ""
        var expectedEscapedValue = false
        while true {
            guard let scalar = readScalar() else { throw Error.streamHasNoData }
            if scalar == "\\" && !expectedEscapedValue {
                expectedEscapedValue = true
            } else if expectedEscapedValue {
                expectedEscapedValue = false
            } else if !expectedEscapedValue && scalar == "\"" {
                break
            }
            string.unicodeScalars.append(scalar)
        }
        storage.setString(string)
        
        try popContext()
    }
    
    private func validateArrayContext(
        _ key: String?,
        _ storage: NSMutableArray,
        expectingAnotherObject: Bool = false) throws
    {
        // [   "object", {}, [], -12.4e4 ]
        //   ^ we're here
        var expectedChars = CharacterSet(["]", "\"", "{", "[", ",", "n", "f", "t"])
        expectedChars.formUnion(numberChars)
        
        let readResult = read(untilAnyCharacterFrom: expectedChars, ignoreCharacters: whiteCharacters)
        guard readResult.passedScalars.isEmpty else { throw Error.unexpectedCharacter(readResult.passedScalars[0]) }
        guard let scalar = readResult.matchingScalar else { throw Error.streamHasNoData }
        
        switch scalar {
        case "]":
            if !expectingAnotherObject {
                try popContext()
            } else {
                throw Error.unexpectedCharacter(scalar)
            }
        case "\"":
            pushContext(.inStringObject(storage: NSMutableString()))
        case "{":
            pushContext(.inObject(key: nil, storage: NSMutableDictionary()))
        case "[":
            pushContext(.inArray(key: nil, storage: NSMutableArray()))
        case ",":
            if storage.count == 0 || expectingAnotherObject {
                throw Error.unexpectedCharacter(scalar)
            }
            try validateArrayContext(key, storage, expectingAnotherObject: true)
        case "n":
            pushContext(.inNullValue(key: nil))
        case "t":
            pushContext(.inTrueValue(key: nil))
        case "f":
            pushContext(.inFalseValue(key: nil))
        case numberChars.contains(scalar) ? scalar : nil:
            pushContext(.inNumericValue(key: nil, storage: NumericStorage(String(scalar))))
        default:
            throw Error.unexpectedCharacter(scalar)
        }
    }
    
    private func validateNullContext() throws {
        // null
        //  ^
        try readAndValidateScalars(["u", "l", "l"])
        try popContext()
    }
    
    private func validateTrueContext() throws {
        // true
        //  ^
        try readAndValidateScalars(["r", "u", "e"])
        try popContext()
    }
    
    private func validateFalseContext() throws {
        // false
        //  ^
        try readAndValidateScalars(["a", "l", "s", "e"])
        try popContext()
    }
    
    private func validateNumericContext(_ key: String?, _ storage: NumericStorage) throws {
        // first symbol ('-' or digit) is part of storage already, so we read the rest
        // 1234.56e-21
        //  ^
        let endOfContainerContextScalar: Unicode.Scalar
        if key == nil {
            // nil key means this number is part of array
            endOfContainerContextScalar = "]"
        } else {
            // non-nil key means this number is part of object key->number
            endOfContainerContextScalar = "}"
        }
        let readBreakers = Set<Unicode.Scalar>([",", endOfContainerContextScalar])
        
        while true {
            guard let nextScalar = inputStream.touch() else { throw Error.streamHasNoData }
            if readBreakers.contains(nextScalar) || whiteCharacters.contains(nextScalar) { break }
            
            guard let scalar = readScalar() else { throw Error.streamHasNoData }
            storage.string.append(String(scalar))
        }
        
        let stringRepresentation = String(storage.string)
        storage.parsedNumber = try NumberValidator.validateStringRepresentationOfNumber(stringRepresentation)
        
        try popContext()
    }
    
    private func read(times: Int) throws -> [Unicode.Scalar] {
        var result = [Unicode.Scalar]()
        for _ in 0 ..< times {
            guard let scalar = readScalar() else { throw Error.streamHasNoData }
            result.append(scalar)
        }
        return result
    }
    
    private func readAndValidateScalars(_ expectedScalars: [Unicode.Scalar]) throws {
        let actualScalars = try read(times: expectedScalars.count)
        guard actualScalars == expectedScalars else {
            throw Error.unexpectedCharacters(actualScalars, expected: expectedScalars)
        }
    }
    
    private func readScalar() -> Unicode.Scalar? {
        guard let scalar = inputStream.read() else { return nil }
        collectedScalars.append(scalar)
        return scalar
    }
    
    /*
     * Reads the input stream up until any scalar from the given set of characters is met.
     * Returns tuple of all scalars that were read from the stream, excluding any characters from ignoreCharacters set,
     * and the scalar that interrupted the read operation.
     * If stream ends, matching scalar will be nil.
     */
    private func read(
        untilAnyCharacterFrom characterSet: CharacterSet,
        ignoreCharacters: CharacterSet? = nil)
        -> (passedScalars: [Unicode.Scalar], matchingScalar: Unicode.Scalar?)
    {
        var passedScalars = [Unicode.Scalar]()
        while true {
            guard let inputScalar = readScalar() else { break }
            if ignoreCharacters?.contains(inputScalar) == true { continue }
            
            if characterSet.contains(inputScalar) {
                return (passedScalars: passedScalars, matchingScalar: inputScalar)
            } else {
                passedScalars.append(inputScalar)
            }
        }
        return (passedScalars: passedScalars, matchingScalar: nil)
    }
    
    // MARK: - Context
    
    private func pushContext(_ context: ParsingContext) {
        self.context.append(context)
    }
    
    private var currentContext: ParsingContext {
        return self.context.last!
    }
    
    private func popContext() throws {
        let popedContext = self.context.removeLast()
        
        switch (popedContext, currentContext) {
            
            /**
             * When parent context is object
             */
        case (.inKey(_), .inObject(_, _)):
            break
        case (.inValue(_), .inObject(_, _)):
            break
        case (.inStringValue(let key, let stringValue), .inObject(_, let object)):
            // case: {"key": "stringValue"}
            guard let key = key else { throw Error.objectMustHaveKey(parent: currentContext, child: popedContext) }
            object[key] = stringValue
        case (.inObject(let key, let objectValue), .inObject(_, let object)):
            // case: {"key": {...}}
            guard let key = key else { throw Error.objectMustHaveKey(parent: currentContext, child: popedContext) }
            object[key] = objectValue
        case (.inArray(let key, let array), .inObject(_, let object)):
            // case: {"key": []]}
            guard let key = key else { throw Error.objectMustHaveKey(parent: currentContext, child: popedContext) }
            object[key] = array
        case (.inNullValue(let key), .inObject(_, let object)):
            // case: {"key": null}
            guard let key = key else { throw Error.objectMustHaveKey(parent: currentContext, child: popedContext) }
            object[key] = NSNull()
        case (.inTrueValue(let key), .inObject(_, let object)):
            // case: {"key": true}
            guard let key = key else { throw Error.objectMustHaveKey(parent: currentContext, child: popedContext) }
            object[key] = true
        case (.inFalseValue(let key), .inObject(_, let object)):
            // case: {"key": false}
            guard let key = key else { throw Error.objectMustHaveKey(parent: currentContext, child: popedContext) }
            object[key] = false
        case (.inNumericValue(let key, let storage), .inObject(_, let object)):
            // case: {"key": -123.45e-3}
            guard let key = key else { throw Error.objectMustHaveKey(parent: currentContext, child: popedContext) }
            guard let parsedNumber = storage.parsedNumber else { throw Error.invalidNumberValue(String(storage.string)) }
            object[key] = parsedNumber
            
            /**
             * When parent context is array
             */
        case (.inStringObject(let string), .inArray(_, let array)):
            // case: ["string"]
            array.add(string)
        case (.inObject(let key, let object), .inArray(_, let array)):
            // case: [{}]
            // arrays do not have keys so key must be nil
            guard key == nil else { throw Error.arrayCannotHaveKeys(parent: currentContext, child: popedContext) }
            array.add(object)
        case (.inArray(let key, let subarray), .inArray(_, let array)):
            // case: [[]]
            // arrays do not have keys so key must be nil
            guard key == nil else { throw Error.arrayCannotHaveKeys(parent: currentContext, child: popedContext) }
            array.add(subarray)
        case (.inNullValue(let key), .inArray(_, let array)):
            // case: [null]
            // arrays do not have keys so key must be nil
            guard key == nil else { throw Error.arrayCannotHaveKeys(parent: currentContext, child: popedContext) }
            array.add(NSNull())
        case (.inTrueValue(let key), .inArray(_, let array)):
            // case: [true]
            // arrays do not have keys so key must be nil
            guard key == nil else { throw Error.arrayCannotHaveKeys(parent: currentContext, child: popedContext) }
            array.add(true)
        case (.inFalseValue(let key), .inArray(_, let array)):
            // case: [false]
            // arrays do not have keys so key must be nil
            guard key == nil else { throw Error.arrayCannotHaveKeys(parent: currentContext, child: popedContext) }
            array.add(false)
        case (.inNumericValue(let key, let storage), .inArray(_, let array)):
            // case: [-123.45e-3]
            // arrays do not have keys so key must be nil
            guard key == nil, let parsedNumber = storage.parsedNumber else { throw Error.invalidNumberValue(String(storage.string)) }
            array.add(parsedNumber)
            
            /**
             * When parent context is root, we expect specific child contexts
             */
        case (.inObject(_, let object), .root):
            eventStream.newObject(NSDictionary(dictionary: object), scalars: collectedScalars)
            collectedScalars.removeAll()
        case (.inArray(_, let array), .root):
            eventStream.newArray(NSArray(array: array), scalars: collectedScalars)
            collectedScalars.removeAll()
        default:
            throw Error.unhandledContextCombination(parent: currentContext, child: popedContext)
        }
    }
}
