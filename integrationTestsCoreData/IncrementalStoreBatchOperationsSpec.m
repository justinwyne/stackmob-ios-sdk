/**
 * Copyright 2012 StackMob
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import <Kiwi/Kiwi.h>
#import "StackMob.h"
#import "SMIntegrationTestHelpers.h"
#import "SMCoreDataIntegrationTestHelpers.h"

SPEC_BEGIN(IncrementalStoreBatchOperationsSpec)

describe(@"Inserting many objects works fine", ^{
    __block SMClient *client = nil;
    __block SMCoreDataStore *cds = nil;
    __block NSManagedObjectContext *moc = nil;
    __block NSMutableArray *arrayOfObjects = nil;
    
    beforeEach(^{
        client = [SMIntegrationTestHelpers defaultClient];
        NSBundle *bundle = [NSBundle bundleForClass:[self class]];
        NSManagedObjectModel *mom = [NSManagedObjectModel mergedModelFromBundles:[NSArray arrayWithObject:bundle]];
        cds = [client coreDataStoreWithManagedObjectModel:mom];
        moc = [cds managedObjectContext];
        arrayOfObjects = [NSMutableArray array];
        for (int i=0; i < 30; i++) {
            NSManagedObject *newManagedObject = [NSEntityDescription insertNewObjectForEntityForName:@"Todo" inManagedObjectContext:moc];
            [newManagedObject setValue:@"bob" forKey:@"title"];
            [newManagedObject setValue:[newManagedObject assignObjectId] forKey:[newManagedObject primaryKeyField]];
            
            [arrayOfObjects addObject:newManagedObject];
        }
    });
    afterEach(^{
        for (NSManagedObject *obj in arrayOfObjects) {
            [moc deleteObject:obj];
        }
        __block NSError *error = nil;
        BOOL saveSuccess = [SMCoreDataIntegrationTestHelpers synchronousSaveInBackgroundWithContext:moc error:&error];
        [[theValue(saveSuccess) should] beYes];
        [arrayOfObjects removeAllObjects];
        
    });
    it(@"saves without error", ^{
        __block BOOL saveSuccess = NO;
        __block NSError *error = nil;
        saveSuccess = [SMCoreDataIntegrationTestHelpers synchronousSaveInBackgroundWithContext:moc error:&error];
        [[theValue(saveSuccess) should] beYes];

        
    });
});


describe(@"With a non-401 error", ^{
    __block SMClient *client = nil;
    __block SMCoreDataStore *cds = nil;
    __block NSManagedObjectContext *moc = nil;
    
    beforeEach(^{
        client = [SMIntegrationTestHelpers defaultClient];
        NSBundle *bundle = [NSBundle bundleForClass:[self class]];
        NSManagedObjectModel *mom = [NSManagedObjectModel mergedModelFromBundles:[NSArray arrayWithObject:bundle]];
        cds = [client coreDataStoreWithManagedObjectModel:mom];
        moc = [cds managedObjectContext];
        
        if ([client isLoggedIn]) {
            syncWithSemaphore(^(dispatch_semaphore_t semaphore) {
                [client logoutOnSuccess:^(NSDictionary *result) {
                    NSLog(@"Logged out");
                    syncReturn(semaphore);
                } onFailure:^(NSError *error) {
                    [error shouldNotBeNil];
                    syncReturn(semaphore);
                }];
            });
        }
    });
    afterEach(^{
        syncWithSemaphore(^(dispatch_semaphore_t semaphore) {
            [[client dataStore] deleteObjectId:@"primarykey" inSchema:@"todo" onSuccess:^(NSString *theObjectId, NSString *schema) {
                syncReturn(semaphore);
            } onFailure:^(NSError *theError, NSString *theObjectId, NSString *schema) {
                [theError shouldBeNil];
                syncReturn(semaphore);
            }];
        });
    });
    it(@"General Error should return", ^{
        NSManagedObject *newManagedObject = [NSEntityDescription insertNewObjectForEntityForName:@"Todo" inManagedObjectContext:moc];
        [newManagedObject setValue:@"bob" forKey:@"title"];
        [newManagedObject setValue:@"primarykey" forKey:[newManagedObject primaryKeyField]];
        NSError *error = nil;
        BOOL success = [SMCoreDataIntegrationTestHelpers synchronousSaveInBackgroundWithContext:moc error:&error];
        [[theValue(success) should] beYes];
        
        NSManagedObject *secondManagedObject = [NSEntityDescription insertNewObjectForEntityForName:@"Todo" inManagedObjectContext:moc];
        [secondManagedObject setValue:@"bob" forKey:@"title"];
        [secondManagedObject setValue:@"primarykey" forKey:[secondManagedObject primaryKeyField]];
        
        success = [SMCoreDataIntegrationTestHelpers synchronousSaveInBackgroundWithContext:moc error:&error];
        [[theValue(success) should] beNo];
        NSArray *failedInsertedObjects = [[error userInfo] objectForKey:SMInsertedObjectFailures];
        
        [failedInsertedObjects shouldNotBeNil];
        [[theValue([failedInsertedObjects count]) should] equal:theValue(1)];
        NSDictionary *dict = [failedInsertedObjects objectAtIndex:0];
        NSError *failedError = [dict objectForKey:SMFailedManagedObjectError];
        [[theValue([failedError code]) should] equal:theValue(SMErrorConflict)];
        NSLog(@"Error is %@", [error userInfo]);
        
        
        
        
    });

    
});



describe(@"With 401s", ^{
    __block SMClient *client = nil;
    __block SMCoreDataStore *cds = nil;
    __block NSManagedObjectContext *moc = nil;
    
    beforeEach(^{
        client = [SMIntegrationTestHelpers defaultClient];
        NSBundle *bundle = [NSBundle bundleForClass:[self class]];
        NSManagedObjectModel *mom = [NSManagedObjectModel mergedModelFromBundles:[NSArray arrayWithObject:bundle]];
        cds = [client coreDataStoreWithManagedObjectModel:mom];
        moc = [cds managedObjectContext];
        
        if ([client isLoggedIn]) {
            syncWithSemaphore(^(dispatch_semaphore_t semaphore) {
                [client logoutOnSuccess:^(NSDictionary *result) {
                    NSLog(@"Logged out");
                    syncReturn(semaphore);
                } onFailure:^(NSError *error) {
                    [error shouldNotBeNil];
                    syncReturn(semaphore);
                }];
            });
        }
    });
    afterEach(^{
        
    });
    
    it(@"Not logged in, 401 should get added to failed operations and show up in error", ^{
        NSManagedObject *newManagedObject = [NSEntityDescription insertNewObjectForEntityForName:@"Oauth2test" inManagedObjectContext:moc];
        [newManagedObject setValue:@"bob" forKey:@"name"];
        [newManagedObject setValue:@"primarykey" forKey:[newManagedObject primaryKeyField]];
        
        [[client.dataStore.session.regularOAuthClient should] receive:@selector(enqueueBatchOfHTTPRequestOperations:completionBlockQueue:progressBlock:completionBlock:) withCount:1];
        
        NSError *error = nil;
        BOOL success = [SMCoreDataIntegrationTestHelpers synchronousSaveInBackgroundWithContext:moc error:&error];
        
        [[theValue(success) should] beNo];
        NSArray *failedInsertedObjects = [[error userInfo] objectForKey:SMInsertedObjectFailures];
        [[theValue([error code]) should] equal:theValue(SMErrorCoreDataSave)];
        [failedInsertedObjects shouldNotBeNil];
        [[theValue([failedInsertedObjects count]) should] equal:theValue(1)];
        NSDictionary *dict = [failedInsertedObjects objectAtIndex:0];
        NSError *failedError = [dict objectForKey:SMFailedManagedObjectError];
        [[theValue([failedError code]) should] equal:theValue(SMErrorUnauthorized)];
        
    });
    
    it(@"Failed refresh before requests are attemtped should error appropriately", ^{
        NSManagedObject *newManagedObject = [NSEntityDescription insertNewObjectForEntityForName:@"Oauth2test" inManagedObjectContext:moc];
        [newManagedObject setValue:@"bob" forKey:@"name"];
        [newManagedObject setValue:@"primarykey" forKey:[newManagedObject primaryKeyField]];
        NSError *error = nil;
        
        [[client.dataStore.session stubAndReturn:@"1234"] refreshToken];
        [[client.dataStore.session stubAndReturn:theValue(YES)] accessTokenHasExpired];
        [[client.dataStore.session stubAndReturn:theValue(NO)] refreshing];
        
        BOOL success = [SMCoreDataIntegrationTestHelpers synchronousSaveInBackgroundWithContext:moc error:&error];
        
        [[theValue(success) should] beNo];
        [[theValue([error code]) should] equal:theValue(SMErrorRefreshTokenFailed)];
        NSArray *failedInsertedObjects = [[error userInfo] objectForKey:SMInsertedObjectFailures];
        [failedInsertedObjects shouldBeNil];
    });
        
});


describe(@"401s requiring logins", ^{
    __block SMClient *client = nil;
    __block SMCoreDataStore *cds = nil;
    __block NSManagedObjectContext *moc = nil;
    
    beforeEach(^{
        client = [SMIntegrationTestHelpers defaultClient];
        NSBundle *bundle = [NSBundle bundleForClass:[self class]];
        NSManagedObjectModel *mom = [NSManagedObjectModel mergedModelFromBundles:[NSArray arrayWithObject:bundle]];
        cds = [client coreDataStoreWithManagedObjectModel:mom];
        moc = [cds managedObjectContext];
        
        syncWithSemaphore(^(dispatch_semaphore_t semaphore) {
            [client loginWithUsername:@"dude" password:@"sweet" onSuccess:^(NSDictionary *result) {
                NSLog(@"logged in, %@", result);
                syncReturn(semaphore);
            } onFailure:^(NSError *error) {
                [error shouldNotBeNil];
                syncReturn(semaphore);
            }];
        });
        
        
    });
    afterEach(^{
        if ([client isLoggedIn]) {
            syncWithSemaphore(^(dispatch_semaphore_t semaphore) {
                [client logoutOnSuccess:^(NSDictionary *result) {
                    NSLog(@"Logged out");
                    syncReturn(semaphore);
                } onFailure:^(NSError *error) {
                    [error shouldNotBeNil];
                    syncReturn(semaphore);
                }];
            });
        }
    });
    it(@"After successful refresh, should send out requests again", ^{
        
                
        NSManagedObject *newManagedObject = [NSEntityDescription insertNewObjectForEntityForName:@"Oauth2test" inManagedObjectContext:moc];
        [newManagedObject setValue:@"bob" forKey:@"name"];
        [newManagedObject setValue:@"primarykey" forKey:[newManagedObject primaryKeyField]];
        
        [[client.dataStore.session stubAndReturn:theValue(YES)] accessTokenHasExpired];
        [[client.dataStore.session stubAndReturn:theValue(NO)] refreshing];
        [[client.dataStore.session stubAndReturn:theValue(YES)] eligibleForTokenRefresh:any()];
        
        [[client.dataStore.session should] receive:@selector(doTokenRequestWithEndpoint:credentials:options:successCallbackQueue:failureCallbackQueue:onSuccess:onFailure:)  withCount:2 arguments:@"refreshToken", any(), any(), any(), any(), any(), any()];
        
        [[client.dataStore.session.regularOAuthClient should] receive:@selector(enqueueBatchOfHTTPRequestOperations:completionBlockQueue:progressBlock:completionBlock:) withCount:2];
        NSError *error = nil;
        BOOL success = [SMCoreDataIntegrationTestHelpers synchronousSaveInBackgroundWithContext:moc error:&error];
        
        [[theValue(success) should] beNo];
        [[theValue([error code]) should] equal:theValue(SMErrorCoreDataSave)];
        NSArray *failedInsertedObjects = [[error userInfo] objectForKey:SMInsertedObjectFailures];
        [[theValue([failedInsertedObjects count] ) should] equal:theValue(1)];
        NSDictionary *dictionary = [failedInsertedObjects objectAtIndex:0];
        [[dictionary objectForKey:SMFailedManagedObjectError] shouldNotBeNil];
        [[dictionary objectForKey:SMFailedManagedObjectID] shouldNotBeNil];
    });

});



describe(@"timeouts with refreshing", ^{
    __block SMClient *client = nil;
    __block SMCoreDataStore *cds = nil;
    __block NSManagedObjectContext *moc = nil;
    
    beforeEach(^{
        client = [SMIntegrationTestHelpers defaultClient];
        NSBundle *bundle = [NSBundle bundleForClass:[self class]];
        NSManagedObjectModel *mom = [NSManagedObjectModel mergedModelFromBundles:[NSArray arrayWithObject:bundle]];
        cds = [client coreDataStoreWithManagedObjectModel:mom];
        moc = [cds managedObjectContext];
        
        
    });
    it(@"waits 5 seconds and fails", ^{
        NSManagedObject *newManagedObject = [NSEntityDescription insertNewObjectForEntityForName:@"Oauth2test" inManagedObjectContext:moc];
        [newManagedObject setValue:@"bob" forKey:@"name"];
        [newManagedObject setValue:@"primarykey" forKey:[newManagedObject primaryKeyField]];
        
        [[client.dataStore.session stubAndReturn:@"1234"] refreshToken];
        [[client.dataStore.session stubAndReturn:theValue(YES)] accessTokenHasExpired];
        [[client.dataStore.session stubAndReturn:theValue(YES)] refreshing];
        
        NSError *error = nil;
        BOOL success = [SMCoreDataIntegrationTestHelpers synchronousSaveInBackgroundWithContext:moc error:&error];
        
        [[theValue(success) should] beNo];
        [[theValue([error code]) should] equal:theValue(SMErrorRefreshTokenInProgress)];
        
    });
    
});


describe(@"With 401s and other errors", ^{
    __block SMClient *client = nil;
    __block SMCoreDataStore *cds = nil;
    __block NSManagedObjectContext *moc = nil;
    
    beforeEach(^{
        client = [SMIntegrationTestHelpers defaultClient];
        NSBundle *bundle = [NSBundle bundleForClass:[self class]];
        NSManagedObjectModel *mom = [NSManagedObjectModel mergedModelFromBundles:[NSArray arrayWithObject:bundle]];
        cds = [client coreDataStoreWithManagedObjectModel:mom];
        moc = [cds managedObjectContext];
        
        syncWithSemaphore(^(dispatch_semaphore_t semaphore) {
            [client loginWithUsername:@"dude" password:@"sweet" onSuccess:^(NSDictionary *result) {
                NSLog(@"logged in, %@", result);
                syncReturn(semaphore);
            } onFailure:^(NSError *error) {
                [error shouldNotBeNil];
                syncReturn(semaphore);
            }];
        });
        
        NSManagedObject *todo = [NSEntityDescription insertNewObjectForEntityForName:@"Todo" inManagedObjectContext:moc];
        [todo setValue:@"bob" forKey:@"title"];
        [todo setValue:@"primarykey" forKey:[todo primaryKeyField]];
        
        NSError *error = nil;
        BOOL success = [SMCoreDataIntegrationTestHelpers synchronousSaveInBackgroundWithContext:moc error:&error];
        [[theValue(success) should] beYes];
        
        
    });
    afterEach(^{
        syncWithSemaphore(^(dispatch_semaphore_t semaphore) {
            [[client dataStore] deleteObjectId:@"primarykey" inSchema:@"todo" onSuccess:^(NSString *theObjectId, NSString *schema) {
                syncReturn(semaphore);
            } onFailure:^(NSError *theError, NSString *theObjectId, NSString *schema) {
                [theError shouldBeNil];
                syncReturn(semaphore);
            }];
        });
        
        if ([client isLoggedIn]) {
            syncWithSemaphore(^(dispatch_semaphore_t semaphore) {
                [client logoutOnSuccess:^(NSDictionary *result) {
                    NSLog(@"Logged out");
                    syncReturn(semaphore);
                } onFailure:^(NSError *error) {
                    [error shouldNotBeNil];
                    syncReturn(semaphore);
                }];
            });
        }
        
    });
    it(@"Only 401s should be refreshed if possible", ^{
        
        // Set up scenario
        [[client.dataStore.session stubAndReturn:theValue(YES)] accessTokenHasExpired];
        [[client.dataStore.session stubAndReturn:theValue(NO)] refreshing];
        [[client.dataStore.session stubAndReturn:theValue(YES)] eligibleForTokenRefresh:any()];
        
        // Add objects for 401 and 409
        NSManagedObject *newManagedObject = [NSEntityDescription insertNewObjectForEntityForName:@"Oauth2test" inManagedObjectContext:moc];
        [newManagedObject setValue:@"bob" forKey:@"name"];
        [newManagedObject setValue:@"primarykey" forKey:[newManagedObject primaryKeyField]];
        
        NSManagedObject *todo = [NSEntityDescription insertNewObjectForEntityForName:@"Todo" inManagedObjectContext:moc];
        [todo setValue:@"bob" forKey:@"title"];
        [todo setValue:@"primarykey" forKey:[todo primaryKeyField]];
        
        // Should create total of 3 operations, one for the 409 and 2 for the 401 (first time and retry)
        [[client.dataStore.session.regularOAuthClient should] receive:@selector(enqueueHTTPRequestOperation:) withCount:3];
        
        NSError *error = nil;
        BOOL success = [SMCoreDataIntegrationTestHelpers synchronousSaveInBackgroundWithContext:moc error:&error];
        [[theValue(success) should] beNo];
        
        // Test failure
        [[theValue([error code]) should] equal:theValue(SMErrorCoreDataSave)];
        NSArray *failedInsertedObjects = [[error userInfo] objectForKey:SMInsertedObjectFailures];
        [[theValue([failedInsertedObjects count] ) should] equal:theValue(2)];
        NSDictionary *dictionary = [failedInsertedObjects objectAtIndex:0];
        [[dictionary objectForKey:SMFailedManagedObjectError] shouldNotBeNil];
        [[dictionary objectForKey:SMFailedManagedObjectID] shouldNotBeNil];
        dictionary = [failedInsertedObjects objectAtIndex:1];
        [[dictionary objectForKey:SMFailedManagedObjectError] shouldNotBeNil];
        [[dictionary objectForKey:SMFailedManagedObjectID] shouldNotBeNil];
        
        
    });
    
});

SPEC_END