//
//  BZFirstUnitSpec.m
//  catch
//
//  Created by Glenna Buford on 9/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OCHamcrest.h"
#import "Kiwi.h"
#import "BZAppDelegate.h"

@interface BZAppDelegate (Test)

-(BOOL)isGameCenterAvailable;
-(void (^)(NSError *error)) authenticationCompletionHandler;

@end

SPEC_BEGIN(GameCenterAuth)

describe(@"GameCenter", ^{
    context(@"authentication", ^{
        __block BZAppDelegate *appDel;
        
        beforeEach(^{
            appDel = [BZAppDelegate new];
        });
        
        it(@"should start authentication process", ^{
            id mockApplication = [KWMock mockForClass:[UIApplication class]];
            id mockLocalPlayer = [KWMock mockForClass:[GKLocalPlayer class]];
            [[theValue(appDel.isGameCenterAuthenticationComplete) should] equal:theValue(NO)];
            [[appDel should] receive:@selector(isGameCenterAvailable) withCount:1];
            [[GKLocalPlayer should] receive:@selector(localPlayer) andReturn:mockLocalPlayer withCount:2];
            [[mockLocalPlayer should] receive:@selector(authenticateWithCompletionHandler:) withCount:1 arguments:any()];
            [[appDel should] receive:@selector(authenticationCompletionHandler) withCount:1 arguments:any()];
            
            [appDel application:mockApplication didFinishLaunchingWithOptions:nil];
        });
        it(@"local player should be authenticated", ^{
            id mockLocalPlayer = [KWMock mockForClass:[GKLocalPlayer class]];
            [[GKLocalPlayer should] receive:@selector(localPlayer) andReturn:mockLocalPlayer withCount:1];
            [mockLocalPlayer stub:@selector(isAuthenticated) andReturn:theValue(YES)];
            NSString *otherPlayerID = @"glenners";
            [mockLocalPlayer stub:@selector(playerID) andReturn:@"glenners"];
            [[theValue(appDel.isGameCenterAuthenticationComplete) should] equal:theValue(NO)];
            [appDel.currentPlayerID shouldBeNil];
            

            NSError *error;
            [appDel authenticationCompletionHandler](error);
            
            [[theValue(appDel.isGameCenterAuthenticationComplete) should] equal:theValue(YES)];
            [appDel.currentPlayerID shouldNotBeNil];
            [[appDel.currentPlayerID should] equal:otherPlayerID];
        });
    });
});

SPEC_END
