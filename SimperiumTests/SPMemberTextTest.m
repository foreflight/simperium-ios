//
//  SPMemberTextTest.m
//  Simperium
//
//  Created by Lukman Sanusi on 10/12/16.
//  Copyright © 2016 Simperium. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "SPMemberText.h"

@interface SPMemberTextTest : XCTestCase
@property (nonatomic, strong) SPMemberText *textMember;
@end

@implementation SPMemberTextTest

- (void)setUp{
    self.textMember = [[SPMemberText alloc] initFromDictionary:@{ @"type" : @"text",
                                                                  @"name" : @"test",
                                                                  @"otype" : OP_REPLACE
                                                                  }];
}

- (void)testTextReplaceOperation {
    NSString *valueA = @"2016-10";
    NSString *valueB = @"2016-05";
    NSString *valueC = @"2016-04";
    
    NSDictionary *diffAB = [self.textMember diff:valueA otherValue:valueB];
    NSDictionary *expectedDiffAB = @{
                                     OP_OP : OP_REPLACE,
                                     OP_VALUE : valueB
                                     };
    
    NSDictionary *diffAC = [self.textMember diff:valueA otherValue:valueC];
    NSDictionary *expectedDiffAC = @{
                                     OP_OP : OP_REPLACE,
                                     OP_VALUE : valueC
                                     };
    
    XCTAssertEqualObjects(diffAB, expectedDiffAB, @"Error obtaining TextReplace Diff");
    XCTAssertEqualObjects(diffAC, expectedDiffAC, @"Error obtaining TextReplace Diff");
}

@end
