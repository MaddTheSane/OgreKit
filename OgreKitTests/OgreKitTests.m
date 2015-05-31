//
//  OgreKitTests.m
//  OgreKitTests
//
//  Created by C.W. Betts on 5/30/15.
//
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>
#import <OgreKit/OgreKit.h>
#import "Calc.h"

@interface OgreKitTests : XCTestCase

@end

@implementation OgreKitTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    // This is an example of a functional test case.
    XCTAssert(YES, @"Pass");
}

- (void)testCaptureTree
{
    NSString    *expr = @"(1+2)*3+4";
    Calc        *calc = [[Calc alloc] init];
    NSNumber    *calced = [calc eval:expr];
    XCTAssertEqualObjects(calced, @13.0, "%@ != 13, actual value: %@", expr, calced);
    
    expr = @"36.5*9/5+32";
    calced = [calc eval:expr];
    XCTAssertEqualObjects(calced, @97.7, "%@ != 97.7, actual value: %@", expr, calced);
}

- (void)testCategory
{
	NSString	*string = @"36.5C, 3.8C, -195.8C";
	//NSLog(@"%@", [[string componentsSeparatedByRegularExpressionString:@"\\s*,\\s*"] description]);
	NSMutableString *mstr = [NSMutableString stringWithString:string];
	NSUInteger	numberOfReplacement = [mstr replaceOccurrencesOfRegularExpressionString:@"C"
																			withString:@"F" options:OgreNoneOption range:NSMakeRange(0, [string length])];
	NSLog(@"%lu %@", (unsigned long)numberOfReplacement, mstr);
	NSRange matchRange = [string rangeOfRegularExpressionString:@"\\s*,\\s*"];
	NSLog(@"(%lu, %lu)", (unsigned long)matchRange.location, (unsigned long)matchRange.length);
}

- (void)testReplace
{
    OGRegularExpression			*regex = [OGRegularExpression regularExpressionWithString:@"a*"];
    NSEnumerator				*matcher = [regex matchEnumeratorInString:@"aaaaaaa" range:NSMakeRange(1, 3)];
    OGRegularExpressionMatch	*match;
    while ((match = [matcher nextObject]) != nil) {
        NSRange matchRange = [match rangeOfMatchedString];
        NSLog(@"(%lu, %lu)", (unsigned long)matchRange.location, (unsigned long)matchRange.length);
    }
}

- (void)testForInFastEnum
{
	OGRegularExpression			*regex = [OGRegularExpression regularExpressionWithString:@"a*"];
	NSEnumerator				*matcher = [regex matchEnumeratorInString:@"aaaaaaa" range:NSMakeRange(1, 3)];
	OGRegularExpressionMatch	*match;
	NSMutableArray				*m1 = [[NSMutableArray alloc] init];
	NSMutableArray				*m2 = [[NSMutableArray alloc] init];

	for (match in matcher) {
		NSRange matchRange = [match rangeOfMatchedString];
		[m1 addObject:[NSValue valueWithRange:matchRange]];
	}
	
	matcher = [regex matchEnumeratorInString:@"aaaaaaa" range:NSMakeRange(1, 3)];
	while ((match = [matcher nextObject]) != nil) {
		NSRange matchRange = [match rangeOfMatchedString];
		[m2 addObject:[NSValue valueWithRange:matchRange]];
	}
	
	XCTAssertEqualObjects(m1, m2);
}

- (void)testReplaceWithDelegate
{
	// Substitution was entrusted with processing to delegate (デリゲートに処理を委ねた置換)
	NSString	*targetString = @"36.5C, 3.8C, -195.8C";
	NSLog(@"%@", targetString);
	OGRegularExpression	*celciusRegex = [OGRegularExpression regularExpressionWithString:@"([+-]?\\d+(?:\\.\\d+)?)C\\b"];
	NSString *fahrenheitString = [celciusRegex replaceAllMatchesInString:targetString
																delegate:self
														 replaceSelector:@selector(fahrenheitFromCelsius:contextInfo:)
															 contextInfo:nil];
	NSLog(@"%@", fahrenheitString);
}

- (void)testSplitString
{
	// I split a string (文字列を分割する)
	NSString	*targetString = @"36.5C, 3.8C, -195.8C";
	OGRegularExpression	*delimiterRegex = [OGRegularExpression regularExpressionWithString:@"\\s*,\\s*"];
	NSLog(@"%@", [[delimiterRegex splitString:targetString] description]);
}

// I convert Celsius to Fahrenheit. (摂氏を華氏に変換する。)
- (NSString *)fahrenheitFromCelsius:(OGRegularExpressionMatch *)aMatch contextInfo:(id)contextInfo
{
    //NSLog(@"matchedString:%@ index:%d", [aMatch matchedString], [aMatch index]);
    double	celcius = [[aMatch substringAtIndex:1] doubleValue];
    double	fahrenheit = celcius * 9.0 / 5.0 + 32.0;
    
    // return the replaced string. to terminate the substitution if it returns nil. (置換した文字列を返す。nilを返した場合は置換を終了する。)
    return [NSString stringWithFormat:@"%.1fF", fahrenheit];
}

@end
