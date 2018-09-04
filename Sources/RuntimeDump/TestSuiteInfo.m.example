#import "TestSuiteInfo.h"
#import <XCTest/XCTest.h>

@implementation TestSuiteInfo

- (instancetype)initWithInstance:(XCTestCase *)testCaseInstance testMethods:(NSArray<NSString *> *)testMethods
{
  self = [super init];
  if (self) {
    _testCaseInstance = testCaseInstance;
    _testMethods = [testMethods copy];
  }
  return self;
}

@end
