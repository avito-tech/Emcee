import Foundation
import TestDiscovery

let parseFunctionSymbolsTestData = [
    // @objc disabled_test..() and bunch of Swift generated symbols - these should be ignored
    "_$s022MainPage_Unit_Default_C5Tests017CommercialServiceE0C024disabled_test_commercialG50CompletionCalledImmediately_whenLoadingIsImmediateyyFTo",
    "_$s022MainPage_Unit_Default_C5Tests017CommercialServiceE0C024disabled_test_commercialG50CompletionCalledImmediately_whenLoadingIsImmediateyyF",
    "_$s022MainPage_Unit_Default_C5Tests017CommercialServiceE0C024disabled_test_commercialG50CompletionCalledImmediately_whenLoadingIsImmediateyyFSSyXEfu1_",
    "_$s022MainPage_Unit_Default_C5Tests017CommercialServiceE0C024disabled_test_commercialG50CompletionCalledImmediately_whenLoadingIsImmediateyyFSSyXEfu1_TA",
    "_$s022MainPage_Unit_Default_C5Tests017CommercialServiceE0C024disabled_test_commercialG50CompletionCalledImmediately_whenLoadingIsImmediateyyFSbyKXEfu_",
    "_$s022MainPage_Unit_Default_C5Tests017CommercialServiceE0C024disabled_test_commercialG50CompletionCalledImmediately_whenLoadingIsImmediateyyFSbyKXEfu_TA",
    "_$s022MainPage_Unit_Default_C5Tests017CommercialServiceE0C024disabled_test_commercialG50CompletionCalledImmediately_whenLoadingIsImmediateyyFy0F00F6BannerCcfU_",
    "_$s022MainPage_Unit_Default_C5Tests017CommercialServiceE0C024disabled_test_commercialG50CompletionCalledImmediately_whenLoadingIsImmediateyyFy0F00F6BannerCcfU_TA",
    
    // @objc test...() and bunch of Swift generated symbols - only a single test should be extracted from this array of symbols
    "_$s022MainPage_Unit_Default_C5Tests0ab18ShortcutsConverterE0C04testabF33_unboxesCorrectly_withOneShortcutyyFTo",
    "_$s022MainPage_Unit_Default_C5Tests0ab18ShortcutsConverterE0C04testabF33_unboxesCorrectly_withOneShortcutyyF",
    "_$s022MainPage_Unit_Default_C5Tests0ab18ShortcutsConverterE0C04testabF33_unboxesCorrectly_withOneShortcutyyFSSyKXEfu1_",
    "_$s022MainPage_Unit_Default_C5Tests0ab18ShortcutsConverterE0C04testabF33_unboxesCorrectly_withOneShortcutyyFSSyKXEfu1_TA",
    "_$s022MainPage_Unit_Default_C5Tests0ab18ShortcutsConverterE0C04testabF33_unboxesCorrectly_withOneShortcutyyFSSyKXEfu2_",
    "_$s022MainPage_Unit_Default_C5Tests0ab18ShortcutsConverterE0C04testabF33_unboxesCorrectly_withOneShortcutyyFSSyKXEfu3_",
    "_$s022MainPage_Unit_Default_C5Tests0ab18ShortcutsConverterE0C04testabF33_unboxesCorrectly_withOneShortcutyyFSSyKXEfu3_TA",
    "_$s022MainPage_Unit_Default_C5Tests0ab18ShortcutsConverterE0C04testabF33_unboxesCorrectly_withOneShortcutyyFSSyKXEfu4_",
    "_$s022MainPage_Unit_Default_C5Tests0ab18ShortcutsConverterE0C04testabF33_unboxesCorrectly_withOneShortcutyyFSiyKXEfu0_",
    "_$s022MainPage_Unit_Default_C5Tests0ab18ShortcutsConverterE0C04testabF33_unboxesCorrectly_withOneShortcutyyFSiyKXEfu_",
    "_$s022MainPage_Unit_Default_C5Tests0ab18ShortcutsConverterE0C04testabF33_unboxesCorrectly_withOneShortcutyyFSiyKXEfu_TA",

    // This is a test method that '@objc () throws -> ()'
    "_$s028DynamicPublish_Unit_Default_C5Tests018CategoryCalculatorE0C04testfg12_returnsLeaff28OfSegment_whenPathToSelectedf8ContainsJ2IdyyKFTo",
    
    // AvitoMessenger_Unit_Default_UnitTests.ChannelsCommercialsServiceImplTests.(YandexContentAdStub in _C0CEFAE3E7CB0120FC877DD09F3F3A61).loadImages
    "_$s028AvitoMessenger_Unit_Default_C5Tests030ChannelsCommercialsServiceImplE0C19YandexContentAdStub028_C0CEFAE3E7CB0120FC877DD09F3T3A61LLC10loadImagesyyFTo",
]

let expectedDiscoveredTestEnries = [
    DiscoveredTestEntry(className: "MainPageShortcutsConverterTests", path: "", testMethods: ["testMainPageShortcuts_unboxesCorrectly_withOneShortcut"], caseId: nil, tags: []),
    DiscoveredTestEntry(className: "CategoryCalculatorTests", path: "", testMethods: ["testCategoryCalculator_returnsLeafCategoryOfSegment_whenPathToSelectedCategoryContainsLeafId"], caseId: nil, tags: []),
]
