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
    
    NSString *outputDiffAB_on_valueA = [self.textMember applyDiff:valueA otherValue:diffAB[OP_VALUE] error:nil];
    NSString *expectedOutputDiffAB_on_valueA = [valueB copy];
    
    NSString *outputDiffAC_on_valueA = [self.textMember applyDiff:valueA otherValue:diffAC[OP_VALUE] error:nil];
    NSString *expectedOutputDiffAC_on_valueA = [valueC copy];
    
    NSString *outputDiffAC_on_outputDiffAB_on_valueA = [self.textMember applyDiff:outputDiffAB_on_valueA otherValue:diffAC[OP_VALUE] error:nil];
    NSString *expectedOutputDiffAC_on_outputDiffAB_on_valueA = [valueC copy];
    
    NSString *outputDiffAB_on_outputDiffAC_on_valueA = [self.textMember applyDiff:outputDiffAC_on_valueA otherValue:diffAB[OP_VALUE] error:nil];
    NSString *expectedOutputDiffAB_on_outputDiffAC_on_valueA = [valueB copy];
    
    
    XCTAssertEqualObjects(diffAB, expectedDiffAB, @"Error obtaining TextReplace Diff");
    XCTAssertEqualObjects(diffAC, expectedDiffAC, @"Error obtaining TextReplace Diff");
    XCTAssertEqualObjects(outputDiffAB_on_valueA, expectedOutputDiffAB_on_valueA, @"Error applying TextReplace Diff");
    XCTAssertEqualObjects(outputDiffAC_on_valueA, expectedOutputDiffAC_on_valueA, @"Error applying TextReplace Diff");
    XCTAssertEqualObjects(outputDiffAC_on_outputDiffAB_on_valueA, expectedOutputDiffAC_on_outputDiffAB_on_valueA, @"Error applying TextReplace Diff");
    XCTAssertEqualObjects(outputDiffAB_on_outputDiffAC_on_valueA, expectedOutputDiffAB_on_outputDiffAC_on_valueA, @"Error applying TextReplace Diff");
}

@end
