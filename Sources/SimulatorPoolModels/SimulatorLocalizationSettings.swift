import Foundation

public struct SimulatorLocalizationSettings: Codable, CustomStringConvertible, Hashable {
    public let localeIdentifier: String
    public let keyboards: [String]
    public let passcodeKeyboards: [String]
    public let languages: [String]
    public let addingEmojiKeybordHandled: Bool
    public let enableKeyboardExpansion: Bool
    public let didShowInternationalInfoAlert: Bool
    public let didShowContinuousPathIntroduction: Bool
    public let didShowGestureKeyboardIntroduction: Bool
    
    public init(
        localeIdentifier: String,
        keyboards: [String],
        passcodeKeyboards: [String],
        languages: [String],
        addingEmojiKeybordHandled: Bool,
        enableKeyboardExpansion: Bool,
        didShowInternationalInfoAlert: Bool,
        didShowContinuousPathIntroduction: Bool,
        didShowGestureKeyboardIntroduction: Bool
    ) {
        self.localeIdentifier = localeIdentifier
        self.keyboards = keyboards
        self.passcodeKeyboards = passcodeKeyboards
        self.languages = languages
        self.addingEmojiKeybordHandled = addingEmojiKeybordHandled
        self.enableKeyboardExpansion = enableKeyboardExpansion
        self.didShowInternationalInfoAlert = didShowInternationalInfoAlert
        self.didShowContinuousPathIntroduction = didShowContinuousPathIntroduction
        self.didShowGestureKeyboardIntroduction = didShowGestureKeyboardIntroduction
    }
    
    public var description: String {
        let keysAndValues = [
            "localeIdentifier: \(localeIdentifier)",
            "keyboards: \(keyboards)",
            "passcodeKeyboards: \(passcodeKeyboards)",
            "languages: \(languages)",
            "addingEmojiKeybordHandled: \(addingEmojiKeybordHandled)",
            "enableKeyboardExpansion: \(enableKeyboardExpansion)",
            "didShowInternationalInfoAlert: \(didShowInternationalInfoAlert)",
            "didShowContinuousPathIntroduction: \(didShowContinuousPathIntroduction)",
            "didShowGestureKeyboardIntroduction: \(didShowGestureKeyboardIntroduction)",
        ].joined(separator: ", ")
        
        return "<\(type(of: self)) \(keysAndValues)>"
    }
}
