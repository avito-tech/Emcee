#import "TestGetter.h"
#import <XCTest/XCTest.h>
#import <objc/runtime.h>
#import "TestSuiteInfo.h"

@implementation TestGetter

- (NSArray<TestSuiteInfo *> *)allTests {
    NSMutableArray *allTests = [NSMutableArray new];
    
    unsigned int classesCount = 0;
    Class *classes = objc_copyClassList(&classesCount);
    for (int classId = 0; classId < classesCount; classId++) {
        Class class = classes[classId];
        Class classPointer = class;
        
        while (classPointer != nil) {
            if (classPointer == [XCTestCase class]) {
                TestSuiteInfo *testInfo = [self testInfoWithClass:class];
                if (testInfo != nil) {
                    [allTests addObject:testInfo];
                }
            }
            
            classPointer = class_getSuperclass(classPointer);
        }
    }
    free(classes);
    
    return [allTests copy];
}

- (TestSuiteInfo *)testInfoWithClass:(Class)testCaseClass {
    if (![testCaseClass isSubclassOfClass:[XCTestCase class]]) {
        return nil;
    }
    
    NSArray *testMethods = [self testMethodsOfClass:testCaseClass];
    
    return [self testInfoWithXcTestCaseClass:testCaseClass testMethods:testMethods];
}

- (TestSuiteInfo *)testInfoWithXcTestCaseClass:(Class)testCaseClass testMethods:(NSArray *)testMethods {
    if (testMethods.count > 0) {
        NSString *anyTestSelector = [testMethods firstObject];
        XCTestCase *testCaseInstance = [self testCaseInstance:testCaseClass selectorName:anyTestSelector];
        if (testCaseInstance != nil) {
            return [[TestSuiteInfo alloc] initWithInstance:testCaseInstance testMethods:testMethods];
        }
    }
    
    return nil;
}

- (NSArray *)testMethodsOfClass:(Class)testCaseClass {
    NSMutableArray *testMethods = [NSMutableArray new];
    
    [self enumerateMethodsOfClass:testCaseClass usingBlock:^(Method method) {
        NSString *selectorName = [self selectorOfMethod:method];
        
        if ([self isTestMethod:method selectorName:selectorName]) {
            [testMethods addObject:selectorName];
        }
    }];
    
    return testMethods;
}

- (void)enumerateMethodsOfClass:(Class)testCaseClass usingBlock:(void (NS_NOESCAPE ^)(Method method))block {
    unsigned int methodsCount = 0;
    Method *methods = class_copyMethodList(testCaseClass, &methodsCount);
    for (unsigned int methodId = 0; methodId < methodsCount; methodId++) {
        Method method = methods[methodId];
        block(method);
    }
    free(methods);
}

- (BOOL)isTestMethod:(Method)method selectorName:(NSString *)selectorName {
    return [self methodHasVoidReturnType:method] && [selectorName hasPrefix:@"test"];
}

- (BOOL)methodHasVoidReturnType:(Method)method {
    char expectedReturnType[] = "v";
    char *actualReturnType = method_copyReturnType(method);
    
    return strcmp(expectedReturnType, actualReturnType) == 0;
}

- (NSString *)selectorOfMethod:(Method)method {
    struct objc_method_description *desc = method_getDescription(method);
    SEL selector = desc->name;
    return NSStringFromSelector(selector);
}

- (XCTestCase *)testCaseInstance:(Class)testCaseClass selectorName:(NSString *)selectorName {
    SEL selector = NSSelectorFromString(selectorName);
    return [self testCaseInstance:testCaseClass selector:selector];
}

- (XCTestCase *)testCaseInstance:(Class)testCaseClass selector:(SEL)selector {
    if ([testCaseClass respondsToSelector:@selector(testCaseWithInvocation:)]) {
        NSInvocation *invocation = [self invocationOfClass:testCaseClass selector:selector];
        return [testCaseClass testCaseWithInvocation:invocation];
    } else {
        return nil;
    }
}

- (NSInvocation *)invocationOfClass:(Class)testCaseClass selector:(SEL)selector {
    NSMethodSignature *methodSignature = [testCaseClass instanceMethodSignatureForSelector:selector];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
    [invocation setSelector:selector];
    return invocation;
}

@end
