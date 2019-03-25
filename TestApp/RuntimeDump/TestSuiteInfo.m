#import "TestSuiteInfo.h"
#import <XCTest/XCTest.h>

NSString *const kSwiftThrowingTestMethodSuffix = @"AndReturnError:";

@implementation TestSuiteInfo
@synthesize testMethods = _testMethods;

- (instancetype)initWithInstance:(XCTestCase *)testCaseInstance
              runtimeTestMethods:(NSArray<NSString *> *)runtimeTestMethods
{
  self = [super init];
  if (self) {
    _testCaseInstance = testCaseInstance;
    _runtimeTestMethods = [runtimeTestMethods copy];
  }
  return self;
}

- (NSArray<NSString *> *)testMethods {
    if (_testMethods == nil) {
        NSMutableArray *testMethods = [[NSMutableArray alloc] init];
        for (NSString *runtimeMethod in self.runtimeTestMethods) {
            [testMethods addObject:[self logicalTestMethodForRuntimeMethod:runtimeMethod]];
        }
        _testMethods = [testMethods copy];
    }
    return _testMethods;
}

- (NSString *)logicalTestMethodForRuntimeMethod:(NSString *)selectorName {
    if ([selectorName hasSuffix:kSwiftThrowingTestMethodSuffix]) {
        return [selectorName substringToIndex:selectorName.length - kSwiftThrowingTestMethodSuffix.length];
    }
    return selectorName;
}

@end
