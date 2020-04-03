import DeveloperDirLocator
import Foundation
import PathLib
import TestDiscovery
import TestHelpers
import XCTest

final class DemanglerTests: XCTestCase {
    lazy var developerDirPath = assertDoesNotThrow {
        try DefaultDeveloperDirLocator().path(developerDir: .current) // WARNING: libswiftDemangle.dylib location may change
    }
    lazy var swiftDemangler = assertDoesNotThrow {
        try LibSwiftDemangler(
            libswiftDemanglePath: developerDirPath.appending(relativePath: RelativePath("Toolchains/XcodeDefault.xctoolchain/usr/lib/libswiftDemangle.dylib"))
        )
    }
    
    func test___foo_bar() {
        XCTAssertEqual(
            try swiftDemangler.demangle(string: "__TFV3foo3BarCfT_S0_"),
            "foo.Bar.init() -> foo.Bar"
        )
    }
    
    func test1() {
        XCTAssertEqual(
            try swiftDemangler.demangle(string: "_$s022MainPage_Unit_Default_C5Tests017CommercialServiceE0C024disabled_test_commercialG50CompletionCalledImmediately_whenLoadingIsImmediateyyF"),
            "MainPage_Unit_Default_UnitTests.CommercialServiceTests.disabled_test_commercialServiceCompletionCalledImmediately_whenLoadingIsImmediate() -> ()"
        )
    }
    
    func test() {
        XCTAssertEqual(
            try swiftDemangler.demangle(string: "_$s022MainPage_Unit_Default_C5Tests0ab5FeedsE0C04testabf26_unboxesCorrectly_withManyF0yyFSSyKXEfu11_TA"),
            "partial apply forwarder for implicit closure #13 () throws -> Swift.String in MainPage_Unit_Default_UnitTests.MainPageFeedsTests.testMainPageFeeds_unboxesCorrectly_withManyFeeds() -> ()"
        )
    }
}
