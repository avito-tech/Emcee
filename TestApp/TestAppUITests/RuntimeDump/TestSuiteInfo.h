#import <Foundation/Foundation.h>

@class XCTestCase;

NS_ASSUME_NONNULL_BEGIN

@interface TestSuiteInfo : NSObject

@property (nonatomic, readonly) XCTestCase *testCaseInstance;
@property (nonatomic, readonly) NSArray<NSString *> *testMethods;

- (instancetype)initWithInstance:(XCTestCase *)testCaseInstance testMethods:(NSArray<NSString *> *)testMethods;

@end

NS_ASSUME_NONNULL_END
