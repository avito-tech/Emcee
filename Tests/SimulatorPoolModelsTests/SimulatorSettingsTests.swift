import SimulatorPoolModels
import SimulatorPoolTestHelpers
import TestHelpers
import XCTest

final class SimulatorSettingsTests: XCTestCase {
    func test___decoding_full_json() throws {
        let json = Data(
            """
            {
                "simulatorLocalizationSettings": {
                    "localeIdentifier": "ru_US",
                    "keyboards": [
                        "ru_RU@sw=Russian;hw=Automatic",
                        "en_US@sw=QWERTY;hw=Automatic"
                    ],
                    "passcodeKeyboards": [
                        "ru_RU@sw=Russian;hw=Automatic",
                        "en_US@sw=QWERTY;hw=Automatic"
                    ],
                    "languages": [
                        "ru-US",
                        "en",
                        "ru-RU"
                    ],
                    "addingEmojiKeybordHandled": true,
                    "enableKeyboardExpansion": true,
                    "didShowInternationalInfoAlert": true,
                    "didShowContinuousPathIntroduction": true,
                    "didShowGestureKeyboardIntroduction": true
                },
                "simulatorKeychainSettings": {
                    "rootCerts": [
                        "http://example.com/cert.zip#cert.pem",
                        "http://example.com/cert2.zip#cert2.pem"
                    ]
                },
                "watchdogSettings": {
                    "bundleIds": [
                        "sample.app"
                    ],
                    "timeout": 42
                },
            }
            """.utf8
        )
        
        let settings = assertDoesNotThrow {
            try JSONDecoder().decode(SimulatorSettings.self, from: json)
        }

        XCTAssertEqual(
            settings,
            SimulatorSettings(
                simulatorLocalizationSettings: SimulatorLocalizationSettingsFixture().simulatorLocalizationSettings(),
                simulatorKeychainSettings: SimulatorKeychainSettings(
                    rootCerts: [
                        SimulatorCertificateLocation(.remoteUrl(URL(string: "http://example.com/cert.zip#cert.pem")!, nil)),
                        SimulatorCertificateLocation(.remoteUrl(URL(string: "http://example.com/cert2.zip#cert2.pem")!, nil))
                    ]
                ),
                watchdogSettings: WatchdogSettings(bundleIds: ["sample.app"], timeout: 42)
            )
        )
    }
    
    func test___decoding_json_without_simulatorKeychainSettings() throws {
        let json = Data(
            """
            {
                "simulatorLocalizationSettings": {
                    "localeIdentifier": "ru_US",
                    "keyboards": [
                        "ru_RU@sw=Russian;hw=Automatic",
                        "en_US@sw=QWERTY;hw=Automatic"
                    ],
                    "passcodeKeyboards": [
                        "ru_RU@sw=Russian;hw=Automatic",
                        "en_US@sw=QWERTY;hw=Automatic"
                    ],
                    "languages": [
                        "ru-US",
                        "en",
                        "ru-RU"
                    ],
                    "addingEmojiKeybordHandled": true,
                    "enableKeyboardExpansion": true,
                    "didShowInternationalInfoAlert": true,
                    "didShowContinuousPathIntroduction": true,
                    "didShowGestureKeyboardIntroduction": true
                },
                "watchdogSettings": {
                    "bundleIds": [
                        "sample.app"
                    ],
                    "timeout": 42
                },
            }
            """.utf8
        )
        
        let settings = assertDoesNotThrow {
            try JSONDecoder().decode(SimulatorSettings.self, from: json)
        }
        
        XCTAssertEqual(
            settings,
            SimulatorSettings(
                simulatorLocalizationSettings: SimulatorLocalizationSettingsFixture().simulatorLocalizationSettings(),
                simulatorKeychainSettings: SimulatorKeychainSettings(
                    rootCerts: []
                ),
                watchdogSettings: WatchdogSettings(bundleIds: ["sample.app"], timeout: 42)
            )
        )
    }
}

