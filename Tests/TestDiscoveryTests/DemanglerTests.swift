import DateProvider
import DeveloperDirLocator
import FileSystem
import Foundation
import PathLib
import ProcessController
import TestDiscovery
import TestHelpers
import XCTest

final class DemanglerTests: XCTestCase {
    lazy var developerDirLocator = DefaultDeveloperDirLocator(
        processControllerProvider: DefaultProcessControllerProvider(
            dateProvider: SystemDateProvider(),
            fileSystem: LocalFileSystem()
        )
    )
    lazy var developerDirPath = assertDoesNotThrow {
        try developerDirLocator.path(developerDir: .current) // WARNING: libswiftDemangle.dylib location may change
    }
    lazy var swiftDemangler = assertDoesNotThrow {
        try LibSwiftDemangler(
            libswiftDemanglePath: developerDirPath.appending(relativePath: RelativePath("Toolchains/XcodeDefault.xctoolchain/usr/lib/libswiftDemangle.dylib"))
        )
    }
    
    func test___foo_bar() {
        XCTAssertEqual(
            try swiftDemangler.demangle(string: "__TFV3foo3BarCfT_S0_", bufferSize: 1024),
            "foo.Bar.init() -> foo.Bar"
        )
    }
    
    func test___demangle_test_name() {
        XCTAssertEqual(
            try swiftDemangler.demangle(
                string: "_$s022MainPage_Unit_Default_C5Tests017CommercialServiceE0C024disabled_test_commercialG50CompletionCalledImmediately_whenLoadingIsImmediateyyF",
                bufferSize: 1024
            ),
            "MainPage_Unit_Default_UnitTests.CommercialServiceTests.disabled_test_commercialServiceCompletionCalledImmediately_whenLoadingIsImmediate() -> ()"
        )
    }
    
    func test___demangle_swift_generated_stuff() {
        XCTAssertEqual(
            try swiftDemangler.demangle(
                string: "_$s022MainPage_Unit_Default_C5Tests0ab5FeedsE0C04testabf26_unboxesCorrectly_withManyF0yyFSSyKXEfu11_TA",
                bufferSize: 1024
            ),
            "partial apply forwarder for implicit closure #13 () throws -> Swift.String in MainPage_Unit_Default_UnitTests.MainPageFeedsTests.testMainPageFeeds_unboxesCorrectly_withManyFeeds() -> ()"
        )
    }
    
    func test___demanging_with_unexisting_dylib___throws() {
        assertThrows {
            try LibSwiftDemangler(
                libswiftDemanglePath: AbsolutePath(components: [UUID().uuidString, UUID().uuidString])
            )
        }
    }
    
    func test___demangling_with_small_buffer___expands_buffer_implicitly() {
        XCTAssertEqual(
            try swiftDemangler.demangle(
                string: "_$s022MainPage_Unit_Default_C5Tests0ab5FeedsE0C04testabf26_unboxesCorrectly_withManyF0yyFSSyKXEfu11_TA",
                bufferSize: 1
            ),
            "partial apply forwarder for implicit closure #13 () throws -> Swift.String in MainPage_Unit_Default_UnitTests.MainPageFeedsTests.testMainPageFeeds_unboxesCorrectly_withManyFeeds() -> ()"
        )
    }
}
