#import <Foundation/Foundation.h>

@class XCTestCase;

NS_ASSUME_NONNULL_BEGIN

extern NSString *const kSwiftThrowingTestMethodSuffix;

@interface TestSuiteInfo : NSObject

@property (nonatomic, readonly) XCTestCase *testCaseInstance;
@property (nonatomic, readonly) NSArray<NSString *> *runtimeTestMethods;
@property (nonatomic, readonly) NSArray<NSString *> *testMethods;

- (instancetype)initWithInstance:(XCTestCase *)testCaseInstance
              runtimeTestMethods:(NSArray<NSString *> *)runtimeTestMethods;

@end

NS_ASSUME_NONNULL_END
