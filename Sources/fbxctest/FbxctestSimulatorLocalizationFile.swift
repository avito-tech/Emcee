import Foundation

struct FbxctestSimulatorLocalizationFile: Encodable {
    let localeIdentifier: String
    let keyboards: [String]
    let passcodeKeyboards: [String]
    let languages: [String]
    let addingEmojiKeybordHandled: Bool
    let enableKeyboardExpansion: Bool
    let didShowInternationalInfoAlert: Bool
    let didShowContinuousPathIntroduction: Bool
    
    enum CodingKeys: String, CodingKey {
        case localeIdentifier = "locale_identifier"
        case keyboards = "keyboards"
        case passcodeKeyboards = "passcode_keyboards"
        case languages = "languages"
        case addingEmojiKeybordHandled = "adding_emoji_keybord_handled"
        case enableKeyboardExpansion = "enable_keyboard_expansion"
        case didShowInternationalInfoAlert = "did_show_international_info_alert"
        case didShowContinuousPathIntroduction = "did_show_continuous_path_introduction"
    }
}
