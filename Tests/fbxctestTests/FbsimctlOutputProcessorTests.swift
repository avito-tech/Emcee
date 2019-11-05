import Foundation
import XCTest
import fbxctest
import ProcessController
import ProcessControllerTestHelpers
import JSONStream

final class FbsimctlOutputProcessorTests: XCTestCase {
    let appendableJsonStream = BlockingArrayBasedJSONStream()
    let processController = FakeProcessController(subprocess: Subprocess(arguments: ["fbsimctl"]))
    
    lazy var processor = FbsimctlOutputProcessor(
        jsonStream: appendableJsonStream,
        processController: processController
    )
    
    let workQueue = DispatchQueue(label: "workQueue")
    let impactQueue = DispatchQueue(label: "impactQueue")
    
    func test___waiting_for_event() throws {
        processController.overridedProcessStatus = .stillRunning

        let workExpectation = expectation(description: "work queue expectation")
        
        workQueue.async {
            defer { workExpectation.fulfill() }
            do {
                let events = try self.processor.waitForEvent(type: .ended, name: .create, timeout: 10)
                guard events.count == 1, let event = events.first else {
                    return XCTFail("Unexpected number of events: \(events.count) instead of 1")
                }
                guard let createEndedEvent = event as? FbSimCtlCreateEndedEvent else {
                    return XCTFail("Event \(event) appears to be not instanse of \(FbSimCtlCreateEndedEvent.self)")
                }
                
                XCTAssertEqual(
                    createEndedEvent,
                    FbSimCtlCreateEndedEvent(
                        timestamp: 1572010777,
                        subject: FbSimCtlCreateEndedEvent.Subject(
                            name: "iPhone X",
                            arch: "x86_64",
                            os: "iOS 12.1",
                            model: "iPhone X",
                            udid: "BC53B27F-E0E2-4996-80D9-EE7B5E9BE05B"
                        )
                    )
                )
            } catch {
                XCTFail("Unexpected error: \(error)")
            }
        }
        
        impactQueue.async {
            self.appendableJsonStream.append(
                scalars: Array("""
                {"event_name":"create","timestamp":1572010777,"subject":{"name":"iPhone X","arch":"x86_64","os":"iOS 12.1","container-pid":0,"model":"iPhone X","udid":"BC53B27F-E0E2-4996-80D9-EE7B5E9BE05B","state":"Shutdown","pid":0},"event_type":"ended"}
                """.unicodeScalars)
            )
        }
        
        wait(for: [workExpectation], timeout: 60.0)
    }
    
    func test___waiting_for_event_with_timeout___throws___and_iterrupts_process() {
        processController.overridedProcessStatus = .stillRunning

        XCTAssertThrowsError(
            try processor.waitForEvent(type: .ended, name: .create, timeout: 1)
        )
        XCTAssertEqual(
            processController.overridedProcessStatus,
            .terminated(exitCode: SIGINT)
        )
    }
    
    func test___waiting_for_event_when_process_does___throws() {
        processController.overridedProcessStatus = .notStarted

        XCTAssertThrowsError(
            try processor.waitForEvent(type: .ended, name: .create, timeout: 1)
        )
    }
    
    func test___waiting_for_event___realdata() throws {
        processController.overridedProcessStatus = .stillRunning

        let workExpectation = expectation(description: "work queue expectation")
        
        workQueue.async {
            defer { workExpectation.fulfill() }
            do {
                let events = try self.processor.waitForEvent(type: .ended, name: .create, timeout: 10)
                guard events.count == 1, let event = events.first else {
                    return XCTFail("Unexpected number of events: \(events.count) instead of 1")
                }
                guard let createEndedEvent = event as? FbSimCtlCreateEndedEvent else {
                    return XCTFail("Event \(event) appears to be not instanse of \(FbSimCtlCreateEndedEvent.self)")
                }
                
                XCTAssertEqual(
                    createEndedEvent,
                    FbSimCtlCreateEndedEvent(
                        timestamp: 1572010777,
                        subject: FbSimCtlCreateEndedEvent.Subject(
                            name: "iPhone X",
                            arch: "x86_64",
                            os: "iOS 12.1",
                            model: "iPhone X",
                            udid: "BC53B27F-E0E2-4996-80D9-EE7B5E9BE05B"
                        )
                    )
                )
            } catch {
                XCTFail("Unexpected error: \(error)")
            }
        }
        
        let contents = """
        {"event_name":"log","timestamp":1572010777,"level":"info","subject":"Monitoring for new profiles in /System/Library/Developer/CoreSimulator/Profiles.  Currently watching for Developer directory to be created. (fd=4)","event_type":"discrete"}
        {"event_name":"log","timestamp":1572010777,"level":"info","subject":"Monitoring for DeviceTypes in /Library/Developer/CoreSimulator/Profiles. (fd=6)","event_type":"discrete"}
        {"event_name":"log","timestamp":1572010777,"level":"info","subject":"Monitoring for Runtimes in /Library/Developer/CoreSimulator/Profiles. (fd=7)","event_type":"discrete"}
        {"event_name":"log","timestamp":1572010777,"level":"info","subject":"Monitoring for new profile bundles in /Library/Developer/CoreSimulator/Profiles/Runtimes. (fd=9)","event_type":"discrete"}
        {"event_name":"log","timestamp":1572010777,"level":"info","subject":"Monitoring for Chrome in /Library/Developer/CoreSimulator/Profiles. (fd=8)","event_type":"discrete"}
        {"event_name":"log","timestamp":1572010777,"level":"info","subject":"Scanning for new runtime profiles in /Library/Developer/CoreSimulator/Profiles/Runtimes","event_type":"discrete"}
        {"event_name":"log","timestamp":1572010777,"level":"info","subject":"Runtime bundle found com.apple.CoreSimulator.SimRuntime.iOS-12-1 : /Library/Developer/CoreSimulator/Profiles/Runtimes/iOS 12.1.simruntime","event_type":"discrete"}
        {"event_name":"log","timestamp":1572010777,"level":"info","subject":"Runtime bundle found com.apple.CoreSimulator.SimRuntime.iOS-10-3 : /Library/Developer/CoreSimulator/Profiles/Runtimes/iOS 10.3.simruntime","event_type":"discrete"}
        {"event_name":"log","timestamp":1572010777,"level":"info","subject":"Runtime bundle found com.apple.CoreSimulator.SimRuntime.iOS-11-3 : /Library/Developer/CoreSimulator/Profiles/Runtimes/iOS 11.3.simruntime","event_type":"discrete"}
        {"event_name":"log","timestamp":1572010777,"level":"info","subject":"Runtime bundle found com.apple.CoreSimulator.SimRuntime.iOS-11-4 : /Library/Developer/CoreSimulator/Profiles/Runtimes/iOS 11.4.simruntime","event_type":"discrete"}
        {"event_name":"log","timestamp":1572010777,"level":"info","subject":"Monitoring for new profiles in /AppleInternal/Library/Developer/CoreSimulator/Profiles.  Currently watching for AppleInternal directory to be created. (fd=7)","event_type":"discrete"}
        {"event_name":"log","timestamp":1572010777,"level":"info","subject":"Monitoring for new profiles in /Users/USER/Library/Developer/CoreSimulator/Profiles.  Currently watching for Profiles directory to be created. (fd=10)","event_type":"discrete"}
        {"event_name":"log","timestamp":1572010777,"level":"info","subject":"Runtime bundle found com.apple.CoreSimulator.SimRuntime.tvOS-12-4 : /Applications/Xcode_10_3.app/Contents/Developer/Platforms/AppleTVOS.platform/Developer/Library/CoreSimulator/Profiles/Runtimes/tvOS.simruntime","event_type":"discrete"}
        {"event_name":"log","timestamp":1572010777,"level":"info","subject":"Device type bundle found com.apple.CoreSimulator.SimDeviceType.Apple-TV-4K-4K : /Applications/Xcode_10_3.app/Contents/Developer/Platforms/AppleTVOS.platform/Developer/Library/CoreSimulator/Profiles/DeviceTypes/Apple TV 4K.simdevicetype","event_type":"discrete"}
        {"event_name":"log","timestamp":1572010777,"level":"info","subject":"Device type bundle found com.apple.CoreSimulator.SimDeviceType.Apple-TV-4K-1080p : /Applications/Xcode_10_3.app/Contents/Developer/Platforms/AppleTVOS.platform/Developer/Library/CoreSimulator/Profiles/DeviceTypes/Apple TV 4K (at 1080p).simdevicetype","event_type":"discrete"}
        {"event_name":"log","timestamp":1572010777,"level":"info","subject":"Device type bundle found com.apple.CoreSimulator.SimDeviceType.Apple-TV-1080p : /Applications/Xcode_10_3.app/Contents/Developer/Platforms/AppleTVOS.platform/Developer/Library/CoreSimulator/Profiles/DeviceTypes/Apple TV.simdevicetype","event_type":"discrete"}
        {"event_name":"log","timestamp":1572010777,"level":"info","subject":"Found device chrome com.apple.CoreSimulator.SimDeviceChrome.tv at '/Applications/Xcode_10_3.app/Contents/Developer/Platforms/AppleTVOS.platform/Developer/Library/CoreSimulator/Profiles/Chrome/tv.simdevicechrome'","event_type":"discrete"}
        {"event_name":"log","timestamp":1572010777,"level":"info","subject":"Runtime bundle found com.apple.CoreSimulator.SimRuntime.iOS-12-4 : /Applications/Xcode_10_3.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/Library/CoreSimulator/Profiles/Runtimes/iOS.simruntime","event_type":"discrete"}
        {"event_name":"log","timestamp":1572010777,"level":"info","subject":"Device type bundle found com.apple.CoreSimulator.SimDeviceType.iPad-Pro : /Applications/Xcode_10_3.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/Library/CoreSimulator/Profiles/DeviceTypes/iPad Pro (12.9-inch).simdevicetype","event_type":"discrete"}
        {"event_name":"log","timestamp":1572010777,"level":"info","subject":"Device type bundle found com.apple.CoreSimulator.SimDeviceType.iPhone-XR : /Applications/Xcode_10_3.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/Library/CoreSimulator/Profiles/DeviceTypes/iPhone Xʀ.simdevicetype","event_type":"discrete"}
        {"event_name":"log","timestamp":1572010777,"level":"info","subject":"Device type bundle found com.apple.CoreSimulator.SimDeviceType.iPhone-6-Plus : /Applications/Xcode_10_3.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/Library/CoreSimulator/Profiles/DeviceTypes/iPhone 6 Plus.simdevicetype","event_type":"discrete"}
        {"event_name":"log","timestamp":1572010777,"level":"info","subject":"Device type bundle found com.apple.CoreSimulator.SimDeviceType.iPhone-8-Plus : /Applications/Xcode_10_3.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/Library/CoreSimulator/Profiles/DeviceTypes/iPhone 8 Plus.simdevicetype","event_type":"discrete"}
        {"event_name":"log","timestamp":1572010777,"level":"info","subject":"Device type bundle found com.apple.CoreSimulator.SimDeviceType.iPhone-XS-Max : /Applications/Xcode_10_3.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/Library/CoreSimulator/Profiles/DeviceTypes/iPhone Xs Max.simdevicetype","event_type":"discrete"}
        {"event_name":"log","timestamp":1572010777,"level":"info","subject":"Device type bundle found com.apple.CoreSimulator.SimDeviceType.iPad-Pro--9-7-inch- : /Applications/Xcode_10_3.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/Library/CoreSimulator/Profiles/DeviceTypes/iPad Pro (9.7-inch).simdevicetype","event_type":"discrete"}
        {"event_name":"log","timestamp":1572010777,"level":"info","subject":"Device type bundle found com.apple.CoreSimulator.SimDeviceType.iPad-mini-4 : /Applications/Xcode_10_3.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/Library/CoreSimulator/Profiles/DeviceTypes/iPad mini 4.simdevicetype","event_type":"discrete"}
        {"event_name":"log","timestamp":1572010777,"level":"info","subject":"Device type bundle found com.apple.CoreSimulator.SimDeviceType.iPad-mini--5th-generation- : /Applications/Xcode_10_3.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/Library/CoreSimulator/Profiles/DeviceTypes/iPad mini (5th generation).simdevicetype","event_type":"discrete"}
        {"event_name":"log","timestamp":1572010777,"level":"info","subject":"Device type bundle found com.apple.CoreSimulator.SimDeviceType.iPad-Pro--10-5-inch- : /Applications/Xcode_10_3.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/Library/CoreSimulator/Profiles/DeviceTypes/iPad Pro (10.5-inch).simdevicetype","event_type":"discrete"}
        {"event_name":"log","timestamp":1572010777,"level":"info","subject":"Device type bundle found com.apple.CoreSimulator.SimDeviceType.iPad-Air--3rd-generation- : /Applications/Xcode_10_3.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/Library/CoreSimulator/Profiles/DeviceTypes/iPad Air (3rd generation).simdevicetype","event_type":"discrete"}
        {"event_name":"log","timestamp":1572010777,"level":"info","subject":"Device type bundle found com.apple.CoreSimulator.SimDeviceType.iPhone-7 : /Applications/Xcode_10_3.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/Library/CoreSimulator/Profiles/DeviceTypes/iPhone 7.simdevicetype","event_type":"discrete"}
        {"event_name":"log","timestamp":1572010777,"level":"info","subject":"Device type bundle found com.apple.CoreSimulator.SimDeviceType.iPad-mini-3 : /Applications/Xcode_10_3.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/Library/CoreSimulator/Profiles/DeviceTypes/iPad mini 3.simdevicetype","event_type":"discrete"}
        {"event_name":"log","timestamp":1572010777,"level":"info","subject":"Device type bundle found com.apple.CoreSimulator.SimDeviceType.iPad-2 : /Applications/Xcode_10_3.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/Library/CoreSimulator/Profiles/DeviceTypes/iPad 2.simdevicetype","event_type":"discrete"}
        {"event_name":"log","timestamp":1572010777,"level":"info","subject":"Device type bundle found com.apple.CoreSimulator.SimDeviceType.iPad--5th-generation- : /Applications/Xcode_10_3.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/Library/CoreSimulator/Profiles/DeviceTypes/iPad (5th generation).simdevicetype","event_type":"discrete"}
        {"event_name":"log","timestamp":1572010777,"level":"info","subject":"Device type bundle found com.apple.CoreSimulator.SimDeviceType.iPad-Air : /Applications/Xcode_10_3.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/Library/CoreSimulator/Profiles/DeviceTypes/iPad Air.simdevicetype","event_type":"discrete"}
        {"event_name":"log","timestamp":1572010777,"level":"info","subject":"Device type bundle found com.apple.CoreSimulator.SimDeviceType.iPad-mini-2 : /Applications/Xcode_10_3.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/Library/CoreSimulator/Profiles/DeviceTypes/iPad mini 2.simdevicetype","event_type":"discrete"}
        {"event_name":"log","timestamp":1572010777,"level":"info","subject":"Device type bundle found com.apple.CoreSimulator.SimDeviceType.iPad--6th-generation- : /Applications/Xcode_10_3.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/Library/CoreSimulator/Profiles/DeviceTypes/iPad (6th generation).simdevicetype","event_type":"discrete"}
        {"event_name":"log","timestamp":1572010777,"level":"info","subject":"Device type bundle found com.apple.CoreSimulator.SimDeviceType.iPhone-6 : /Applications/Xcode_10_3.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/Library/CoreSimulator/Profiles/DeviceTypes/iPhone 6.simdevicetype","event_type":"discrete"}
        {"event_name":"log","timestamp":1572010777,"level":"info","subject":"Device type bundle found com.apple.CoreSimulator.SimDeviceType.iPhone-5s : /Applications/Xcode_10_3.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/Library/CoreSimulator/Profiles/DeviceTypes/iPhone 5s.simdevicetype","event_type":"discrete"}
        {"event_name":"log","timestamp":1572010777,"level":"info","subject":"Device type bundle found com.apple.CoreSimulator.SimDeviceType.iPad-Pro--12-9-inch---3rd-generation- : /Applications/Xcode_10_3.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/Library/CoreSimulator/Profiles/DeviceTypes/iPad Pro (12.9-inch) (3rd generation).simdevicetype","event_type":"discrete"}
        {"event_name":"log","timestamp":1572010777,"level":"info","subject":"Device type bundle found com.apple.CoreSimulator.SimDeviceType.iPhone-SE : /Applications/Xcode_10_3.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/Library/CoreSimulator/Profiles/DeviceTypes/iPhone SE.simdevicetype","event_type":"discrete"}
        {"event_name":"log","timestamp":1572010777,"level":"info","subject":"Device type bundle found com.apple.CoreSimulator.SimDeviceType.iPhone-4s : /Applications/Xcode_10_3.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/Library/CoreSimulator/Profiles/DeviceTypes/iPhone 4s.simdevicetype","event_type":"discrete"}
        {"event_name":"log","timestamp":1572010777,"level":"info","subject":"Device type bundle found com.apple.CoreSimulator.SimDeviceType.iPad-Air-2 : /Applications/Xcode_10_3.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/Library/CoreSimulator/Profiles/DeviceTypes/iPad Air 2.simdevicetype","event_type":"discrete"}
        {"event_name":"log","timestamp":1572010777,"level":"info","subject":"Device type bundle found com.apple.CoreSimulator.SimDeviceType.iPhone-X : /Applications/Xcode_10_3.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/Library/CoreSimulator/Profiles/DeviceTypes/iPhone X.simdevicetype","event_type":"discrete"}
        {"event_name":"log","timestamp":1572010777,"level":"info","subject":"Device type bundle found com.apple.CoreSimulator.SimDeviceType.iPhone-5 : /Applications/Xcode_10_3.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/Library/CoreSimulator/Profiles/DeviceTypes/iPhone 5.simdevicetype","event_type":"discrete"}
        {"event_name":"log","timestamp":1572010777,"level":"info","subject":"Device type bundle found com.apple.CoreSimulator.SimDeviceType.iPhone-6s : /Applications/Xcode_10_3.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/Library/CoreSimulator/Profiles/DeviceTypes/iPhone 6s.simdevicetype","event_type":"discrete"}
        {"event_name":"log","timestamp":1572010777,"level":"info","subject":"Device type bundle found com.apple.CoreSimulator.SimDeviceType.iPad-Pro--11-inch- : /Applications/Xcode_10_3.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/Library/CoreSimulator/Profiles/DeviceTypes/iPad Pro (11-inch).simdevicetype","event_type":"discrete"}
        {"event_name":"log","timestamp":1572010777,"level":"info","subject":"Device type bundle found com.apple.CoreSimulator.SimDeviceType.iPad-Retina : /Applications/Xcode_10_3.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/Library/CoreSimulator/Profiles/DeviceTypes/iPad Retina.simdevicetype","event_type":"discrete"}
        {"event_name":"log","timestamp":1572010777,"level":"info","subject":"Device type bundle found com.apple.CoreSimulator.SimDeviceType.iPad-Pro--12-9-inch---2nd-generation- : /Applications/Xcode_10_3.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/Library/CoreSimulator/Profiles/DeviceTypes/iPad Pro (12.9-inch) (2nd generation).simdevicetype","event_type":"discrete"}
        {"event_name":"log","timestamp":1572010777,"level":"info","subject":"Device type bundle found com.apple.CoreSimulator.SimDeviceType.iPhone-7-Plus : /Applications/Xcode_10_3.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/Library/CoreSimulator/Profiles/DeviceTypes/iPhone 7 Plus.simdevicetype","event_type":"discrete"}
        {"event_name":"log","timestamp":1572010777,"level":"info","subject":"Device type bundle found com.apple.CoreSimulator.SimDeviceType.iPhone-XS : /Applications/Xcode_10_3.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/Library/CoreSimulator/Profiles/DeviceTypes/iPhone Xs.simdevicetype","event_type":"discrete"}
        {"event_name":"log","timestamp":1572010777,"level":"info","subject":"Device type bundle found com.apple.CoreSimulator.SimDeviceType.iPhone-6s-Plus : /Applications/Xcode_10_3.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/Library/CoreSimulator/Profiles/DeviceTypes/iPhone 6s Plus.simdevicetype","event_type":"discrete"}
        {"event_name":"log","timestamp":1572010777,"level":"info","subject":"Device type bundle found com.apple.CoreSimulator.SimDeviceType.iPhone-8 : /Applications/Xcode_10_3.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/Library/CoreSimulator/Profiles/DeviceTypes/iPhone 8.simdevicetype","event_type":"discrete"}
        {"event_name":"log","timestamp":1572010777,"level":"info","subject":"Found device chrome com.apple.CoreSimulator.SimDeviceChrome.phone2 at '/Applications/Xcode_10_3.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/Library/CoreSimulator/Profiles/Chrome/phone2.simdevicechrome'","event_type":"discrete"}
        {"event_name":"log","timestamp":1572010777,"level":"info","subject":"Found device chrome com.apple.CoreSimulator.SimDeviceChrome.tablet2 at '/Applications/Xcode_10_3.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/Library/CoreSimulator/Profiles/Chrome/tablet2.simdevicechrome'","event_type":"discrete"}
        {"event_name":"log","timestamp":1572010777,"level":"info","subject":"Found device chrome com.apple.CoreSimulator.SimDeviceChrome.phone at '/Applications/Xcode_10_3.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/Library/CoreSimulator/Profiles/Chrome/phone.simdevicechrome'","event_type":"discrete"}
        {"event_name":"log","timestamp":1572010777,"level":"info","subject":"Found device chrome com.apple.CoreSimulator.SimDeviceChrome.tablet at '/Applications/Xcode_10_3.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/Library/CoreSimulator/Profiles/Chrome/tablet.simdevicechrome'","event_type":"discrete"}
        {"event_name":"log","timestamp":1572010777,"level":"info","subject":"Runtime bundle found com.apple.CoreSimulator.SimRuntime.watchOS-5-3 : /Applications/Xcode_10_3.app/Contents/Developer/Platforms/WatchOS.platform/Developer/Library/CoreSimulator/Profiles/Runtimes/watchOS.simruntime","event_type":"discrete"}
        {"event_name":"log","timestamp":1572010777,"level":"info","subject":"Device type bundle found com.apple.CoreSimulator.SimDeviceType.Apple-Watch-42mm : /Applications/Xcode_10_3.app/Contents/Developer/Platforms/WatchOS.platform/Developer/Library/CoreSimulator/Profiles/DeviceTypes/Apple Watch - 42mm.simdevicetype","event_type":"discrete"}
        {"event_name":"log","timestamp":1572010777,"level":"info","subject":"Device type bundle found com.apple.CoreSimulator.SimDeviceType.Apple-Watch-38mm : /Applications/Xcode_10_3.app/Contents/Developer/Platforms/WatchOS.platform/Developer/Library/CoreSimulator/Profiles/DeviceTypes/Apple Watch - 38mm.simdevicetype","event_type":"discrete"}
        {"event_name":"log","timestamp":1572010777,"level":"info","subject":"Device type bundle found com.apple.CoreSimulator.SimDeviceType.Apple-Watch-Series-4-44mm : /Applications/Xcode_10_3.app/Contents/Developer/Platforms/WatchOS.platform/Developer/Library/CoreSimulator/Profiles/DeviceTypes/Apple Watch Series 4 - 44mm.simdevicetype","event_type":"discrete"}
        {"event_name":"log","timestamp":1572010777,"level":"info","subject":"Device type bundle found com.apple.CoreSimulator.SimDeviceType.Apple-Watch-Series-3-38mm : /Applications/Xcode_10_3.app/Contents/Developer/Platforms/WatchOS.platform/Developer/Library/CoreSimulator/Profiles/DeviceTypes/Apple Watch Series 3 - 38mm.simdevicetype","event_type":"discrete"}
        {"event_name":"log","timestamp":1572010777,"level":"info","subject":"Device type bundle found com.apple.CoreSimulator.SimDeviceType.Apple-Watch-Series-3-42mm : /Applications/Xcode_10_3.app/Contents/Developer/Platforms/WatchOS.platform/Developer/Library/CoreSimulator/Profiles/DeviceTypes/Apple Watch Series 3 - 42mm.simdevicetype","event_type":"discrete"}
        {"event_name":"log","timestamp":1572010777,"level":"info","subject":"Device type bundle found com.apple.CoreSimulator.SimDeviceType.Apple-Watch-Series-2-42mm : /Applications/Xcode_10_3.app/Contents/Developer/Platforms/WatchOS.platform/Developer/Library/CoreSimulator/Profiles/DeviceTypes/Apple Watch Series 2 - 42mm.simdevicetype","event_type":"discrete"}
        {"event_name":"log","timestamp":1572010777,"level":"info","subject":"Device type bundle found com.apple.CoreSimulator.SimDeviceType.Apple-Watch-Series-2-38mm : /Applications/Xcode_10_3.app/Contents/Developer/Platforms/WatchOS.platform/Developer/Library/CoreSimulator/Profiles/DeviceTypes/Apple Watch Series 2 - 38mm.simdevicetype","event_type":"discrete"}
        {"event_name":"log","timestamp":1572010777,"level":"info","subject":"Device type bundle found com.apple.CoreSimulator.SimDeviceType.Apple-Watch-Series-4-40mm : /Applications/Xcode_10_3.app/Contents/Developer/Platforms/WatchOS.platform/Developer/Library/CoreSimulator/Profiles/DeviceTypes/Apple Watch Series 4 - 40mm.simdevicetype","event_type":"discrete"}
        {"event_name":"log","timestamp":1572010777,"level":"info","subject":"Found device chrome com.apple.CoreSimulator.SimDeviceChrome.watch2b at '/Applications/Xcode_10_3.app/Contents/Developer/Platforms/WatchOS.platform/Developer/Library/CoreSimulator/Profiles/Chrome/watch2b.simdevicechrome'","event_type":"discrete"}
        {"event_name":"log","timestamp":1572010777,"level":"info","subject":"Found device chrome com.apple.CoreSimulator.SimDeviceChrome.watch2 at '/Applications/Xcode_10_3.app/Contents/Developer/Platforms/WatchOS.platform/Developer/Library/CoreSimulator/Profiles/Chrome/watch2.simdevicechrome'","event_type":"discrete"}
        {"event_name":"log","timestamp":1572010777,"level":"info","subject":"Found device chrome com.apple.CoreSimulator.SimDeviceChrome.watch at '/Applications/Xcode_10_3.app/Contents/Developer/Platforms/WatchOS.platform/Developer/Library/CoreSimulator/Profiles/Chrome/watch.simdevicechrome'","event_type":"discrete"}
        {"event_name":"create","timestamp":1572010777,"subject":{"device":"iPhone X","os":"iOS 12.1","aux_directory":null,"architecture":"x86_64"},"event_type":"started"}
        {"event_name":"create","timestamp":1572010777,"subject":{"name":"iPhone X","arch":"x86_64","os":"iOS 12.1","container-pid":0,"model":"iPhone X","udid":"BC53B27F-E0E2-4996-80D9-EE7B5E9BE05B","state":"Shutdown","pid":0},"event_type":"ended"}
        """
        
        impactQueue.async {
            self.appendableJsonStream.append(scalars: Array(contents.unicodeScalars))
        }
        
        wait(for: [workExpectation], timeout: 60.0)
    }
}
