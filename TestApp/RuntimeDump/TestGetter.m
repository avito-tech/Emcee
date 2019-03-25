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

+ (NSSet<NSString *> *)classNamesToRemoveFromRuntimeDump {
    return [NSSet setWithObjects:
            @"Test_XCTestObservation",
            @"Test_XCTestObservationCenter",
            nil];
}

- (TestSuiteInfo *)testInfoWithClass:(Class)testCaseClass {
    if (![testCaseClass isSubclassOfClass:[XCTestCase class]]) {
        return nil;
    }
    if ([[self.class classNamesToRemoveFromRuntimeDump] containsObject:NSStringFromClass(testCaseClass)]) {
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
            return [[TestSuiteInfo alloc] initWithInstance:testCaseInstance runtimeTestMethods:testMethods];
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
    if (![selectorName hasPrefix:@"test"]) { return NO; }
    
    BOOL methodIsVoid = [self methodHasVoidReturnType:method];
    BOOL methodIsBool = [self methodHasBOOLReturnType:method];
    BOOL swiftTestMethodThrowsError = [selectorName hasSuffix:kSwiftThrowingTestMethodSuffix];
    NSUInteger numberOfArguments = [self numberOfArgumentsInMethod:method] - 2;  // exclude self and cmd
    
    return (methodIsVoid && numberOfArguments == 0) || (methodIsBool && swiftTestMethodThrowsError && numberOfArguments == 1);
}

- (BOOL)methodHasVoidReturnType:(Method)method {
    return [self method:method hasReturnType:"v"];
}

- (BOOL)methodHasBOOLReturnType:(Method)method {
    return [self method:method hasReturnType:"B"];
}

- (BOOL)method:(Method)method hasReturnType:(char [])expectedReturnType {
    char *actualReturnType = method_copyReturnType(method);
    BOOL result = strcmp(expectedReturnType, actualReturnType) == 0;
    free(actualReturnType);
    return result;
}

- (NSString *)selectorOfMethod:(Method)method {
    struct objc_method_description *desc = method_getDescription(method);
    SEL selector = desc->name;
    return NSStringFromSelector(selector);
}

- (NSUInteger)numberOfArgumentsInMethod:(Method)method {
    struct objc_method_description *desc = method_getDescription(method);
    return [NSMethodSignature signatureWithObjCTypes:desc->types].numberOfArguments;
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
