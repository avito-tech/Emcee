import Foundation
import SimulatorPoolModels

public final class SimulatorLocalizationSettingsFixture {
    public var localeIdentifier = "ru_US"
    public var keyboards = ["ru_RU@sw=Russian;hw=Automatic", "en_US@sw=QWERTY;hw=Automatic"]
    public var passcodeKeyboards = ["ru_RU@sw=Russian;hw=Automatic", "en_US@sw=QWERTY;hw=Automatic"]
    public var languages = ["ru-US", "en", "ru-RU"]
    public var addingEmojiKeybordHandled = true
    public var enableKeyboardExpansion = true
    public var didShowInternationalInfoAlert = true
    public var didShowContinuousPathIntroduction = true
    public var didShowGestureKeyboardIntroduction = true
    
    public init() {}
    
    public func simulatorLocalizationSettings() -> SimulatorLocalizationSettings {
        return SimulatorLocalizationSettings(
            localeIdentifier: localeIdentifier,
            keyboards: keyboards,
            passcodeKeyboards: passcodeKeyboards,
            languages: languages,
            addingEmojiKeybordHandled: addingEmojiKeybordHandled,
            enableKeyboardExpansion: enableKeyboardExpansion,
            didShowInternationalInfoAlert: didShowInternationalInfoAlert,
            didShowContinuousPathIntroduction: didShowContinuousPathIntroduction,
            didShowGestureKeyboardIntroduction: didShowGestureKeyboardIntroduction
        )
    }
}
