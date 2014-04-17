//
//  SPRelationshipResolverTests.m
//  Simperium
//
//  Created by Jorge Leandro Perez on 4/17/14.
//  Copyright (c) 2014 Simperium. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "SPRelationshipResolver.h"
#import "MockStorage.h"
#import "XCTestCase+Simperium.h"
#import "NSString+Simperium.h"
#import "SPObject.h"


#pragma mark ====================================================================================
#pragma mark Constants
#pragma mark ====================================================================================

static NSString *SPTestSourceBucket     = @"SPMockSource";
static NSString *SPTestSourceAttribute  = @"target";

static NSString *SPTestTargetBucket     = @"SPMockTarget";

static NSString *SPLegacyPathKey        = @"SPPathKey";
static NSString *SPLegacyPathBucket     = @"SPPathBucket";
static NSString *SPLegacyPathAttribute  = @"SPPathAttribute";
static NSString *SPLegacyPendingsKey    = @"SPPendingReferences";

static NSInteger SPTestIterations       = 100;
static NSInteger SPTestSubIterations    = 10;


#pragma mark ====================================================================================
#pragma mark Interface
#pragma mark ====================================================================================

@interface SPRelationshipResolverTests : XCTestCase
@property (nonatomic, strong) SPRelationshipResolver    *resolver;
@property (nonatomic, strong) MockStorage               *storage;
@end


#pragma mark ====================================================================================
#pragma mark SPRelationshipResolverTests!
#pragma mark ====================================================================================

@implementation SPRelationshipResolverTests

- (void)setUp
{
    [super setUp];
    self.resolver   = [SPRelationshipResolver new];
    self.storage    = [MockStorage new];
}

- (void)testSetPendingRelationships {
    
    // Set 'SPTestIterations' pending relationships
    NSMutableArray *sourceKeys = [NSMutableArray array];
    NSMutableArray *targetKeys = [NSMutableArray array];
    
    for (NSInteger i = 0; ++i <= SPTestIterations; ) {
        NSString *sourceKey = [NSString sp_makeUUID];
        NSString *targetKey = [NSString sp_makeUUID];

        [self.resolver setPendingRelationshipBetweenKey:sourceKey fromAttribute:SPTestSourceAttribute inBucket:SPTestSourceBucket
                                          withTargetKey:targetKey andTargetBucket:SPTestTargetBucket storage:self.storage];
        
        [sourceKeys addObject:sourceKey];
        [targetKeys addObject:targetKey];
    }
    
    // Verify
    XCTAssert( [self.resolver countPendingRelationships] == SPTestIterations, @"Inconsistency found" );

    for (NSInteger i = 0; ++i < SPTestIterations; ) {
        NSString *sourceKey = sourceKeys[i];
        NSString *targetKey = targetKeys[i];

        XCTAssertTrue( [self.resolver verifyBidireccionalMappingBetweenKey:sourceKey andKey:targetKey], @"Error in bidirectional mapping" );
        XCTAssertTrue( [self.resolver countPendingRelationshipsWithSourceKey:sourceKey andTargetKey:targetKey] == 1, @"Error while checking pending relationships" );
    }
}

- (void)testLoadingPendingRelationships {
    
    // Set 'SPTestIterations' pending relationships
    NSMutableArray *sourceKeys = [NSMutableArray array];
    NSMutableArray *targetKeys = [NSMutableArray array];
    
    for (NSInteger i = 0; ++i <= SPTestIterations; ) {
        NSString *sourceKey = [NSString sp_makeUUID];
        NSString *targetKey = [NSString sp_makeUUID];
        
        [self.resolver setPendingRelationshipBetweenKey:sourceKey fromAttribute:SPTestSourceAttribute inBucket:SPTestSourceBucket
                                          withTargetKey:targetKey andTargetBucket:SPTestTargetBucket storage:self.storage];
        
        [sourceKeys addObject:sourceKey];
        [targetKeys addObject:targetKey];
    }
    
    // Save OP is async
    [self waitFor:1.0];
    
    // ""Simulate"" App Relaungh
    self.resolver = [SPRelationshipResolver new];
    [self.resolver loadPendingRelationships:self.storage];
    
    // Verify
    XCTAssert( [self.resolver countPendingRelationships] == SPTestIterations, @"Inconsistency found" );
    
    for (NSInteger i = 0; ++i < SPTestIterations; ) {
        NSString *sourceKey = sourceKeys[i];
        NSString *targetKey = targetKeys[i];
        
        XCTAssertTrue( [self.resolver verifyBidireccionalMappingBetweenKey:sourceKey andKey:targetKey], @"Error in bidirectional mapping" );
        XCTAssertTrue( [self.resolver countPendingRelationshipsWithSourceKey:sourceKey andTargetKey:targetKey] == 1, @"Error while checking pending relationships" );
    }
}

- (void)testMigrateLegacyRelationships {
    // Set 'SPTestIterations x SPTestIterations' pending legacy relationships
    NSMutableDictionary *legacy = [NSMutableDictionary dictionary];
    
    for (NSInteger i = 0; ++i <= SPTestIterations; ) {
        NSString *targetKey = [NSString sp_makeUUID];
    
        NSMutableArray *relationships = [NSMutableArray array];
        for (NSInteger j = 0; ++j <= SPTestSubIterations; ) {
            [relationships addObject: @{
                SPLegacyPathKey          : [NSString sp_makeUUID],
                SPLegacyPathBucket       : SPTestSourceBucket,
                SPLegacyPathAttribute    : SPTestSourceAttribute
                }];
        }
        
        legacy[targetKey] = relationships;
    }
    
    NSMutableDictionary *metadata   = [NSMutableDictionary dictionary];
    metadata[SPLegacyPendingsKey]   = legacy;
    self.storage.metadata           = metadata;

    // Sanity Check
    XCTAssertTrue( [self.resolver countPendingRelationships] == 0, @"Inconsistency Detected");
    
    // Load
    [self.resolver loadPendingRelationships:self.storage];
    
    XCTAssertTrue( [self.resolver countPendingRelationships] == SPTestIterations * SPTestSubIterations, @"Inconsistency Detected");
 
    // Verify
    for (NSString *targetKey in [legacy allKeys]) {
        
        for (NSDictionary *legacyDescriptor in legacy[targetKey]) {
            NSString *sourceKey = legacyDescriptor[SPLegacyPathKey];
            
            XCTAssertTrue( [self.resolver verifyBidireccionalMappingBetweenKey:sourceKey andKey:targetKey], @"Inconsistency Detected" );
            XCTAssertTrue( [self.resolver countPendingRelationshipsWithSourceKey:sourceKey andTargetKey:targetKey] == 1, @"Inconsistency Detected" );
        }
    }
}

- (void)testResetPendingRelationships {
    // Set SPTestIterations pendings
    for (NSInteger i = 0; ++i <= SPTestIterations; ) {
        NSString *sourceKey = [NSString sp_makeUUID];
        NSString *targetKey = [NSString sp_makeUUID];
        
        [self.resolver setPendingRelationshipBetweenKey:sourceKey fromAttribute:SPTestSourceAttribute inBucket:SPTestSourceBucket
                                          withTargetKey:targetKey andTargetBucket:SPTestTargetBucket storage:self.storage];
    }
    
    XCTAssertTrue( [self.resolver countPendingRelationships] == SPTestIterations, @"Inconsistency detected" );

    [self.resolver reset:self.storage];
    
    XCTAssertTrue( [self.resolver countPendingRelationships] == 0, @"Inconsistency detected" );
}

- (void)testResolvePendingRelationshipWithSourceObjectMissing {
    // New Objects please
    SPObject *target    = [SPObject new];
    target.simperiumKey = [NSString sp_makeUUID];
    
    SPObject *source    = [SPObject new];
    source.simperiumKey = [NSString sp_makeUUID];

    // Set the pending relationship
    [self.resolver setPendingRelationshipBetweenKey:source.simperiumKey
                                      fromAttribute:SPTestSourceAttribute
                                           inBucket:SPTestSourceBucket
                                      withTargetKey:target.simperiumKey
                                    andTargetBucket:SPTestTargetBucket
                                            storage:self.storage];
    XCTAssertTrue( [self.resolver countPendingRelationships] == 1, @"Inconsistency detected" );
    
    // Insert Target
    [self.storage insertObject:target bucketName:SPTestTargetBucket];
    XCTAssertTrue( [self.storage numObjectsForBucketName:SPTestTargetBucket predicate:nil] == 1, @"Inconsistency detected" );
    
    // Attempt to resolve. This should not do anything
    [self.resolver resolvePendingRelationshipsForKey:target.simperiumKey bucketName:SPTestTargetBucket storage:self.storage];
    
    // Resolver works in a BG thread. Wait a sec...
    [self waitFor:1.0f];
    XCTAssertTrue( [self.resolver countPendingRelationships] == 1, @"Inconsistency detected" );
    
    // Insert Source
    [self.storage insertObject:source bucketName:SPTestSourceBucket];
    [self.resolver resolvePendingRelationshipsForKey:source.simperiumKey bucketName:SPTestSourceBucket storage:self.storage];
    
    // Wait..
    [self waitFor:1.0f];
    XCTAssertTrue( [self.resolver countPendingRelationships] == 0, @"Inconsistency detected" );
    XCTAssert([source simperiumValueForKey:SPTestSourceAttribute] == target, @"Inconsistency detected" );
}

- (void)testResolvePendingRelationshipWithTargetObjectMissing {
#warning Implement Me!
}

- (void)testResolvePendingRelationshipWithBothObjectsInserted {
#warning Implement Me!
}

- (void)testIfPendingRelationshipsGetNukedAfterBeingResolved {
#warning Implement Me!
}

@end
