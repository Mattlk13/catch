//
//  BZViewControllerSpec.m
//  catch
//
//  Created by Glenna Buford on 9/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OCHamcrest.h"
#import "Kiwi.h"
#import "BZVCConstants.h"
#import "BZViewController.h"

@interface BZViewController (Test)

@property (strong, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) IBOutlet UIButton *connectButton;

@property (nonatomic, strong) GKSession *gameSession;
@property (nonatomic, strong) NSString *gamePeerID;
@property (nonatomic, readwrite) BOOL rotating;
@property (nonatomic) NSInteger gameState;
@property (nonatomic) NSInteger gameUniqueId;
@property (nonatomic) CGFloat objectWidth;
@property (nonatomic) CGFloat objectHeight;
@property (nonatomic) CGFloat yPosOfObject;
@property (nonatomic) CGFloat xPosOfObject;
@property (nonatomic, readwrite) BOOL isThrowing;
@property (nonatomic) UIAlertView *alert;
@property (nonatomic) double lastAccelerometerUpdateAction;

-(void)startPicker;
-(GKPeerPickerController*)getPeerPicker;
-(GKSession*)getSession;
-(void)invalidateSession:(GKSession*)session;
- (void)sendNetworkPacket:(GKSession *)session packetID:(int)packetID withData:(void *)data ofLength:(int)length;

@end


SPEC_BEGIN(ViewController)

describe(@"BZViewController", ^{
    __block BZViewController *bzvc;
    beforeEach(^{
        bzvc = [[BZViewController alloc] init];
    });
    afterEach(^{
        bzvc = nil;
    });
    context(@"ViewDidLoad", ^{
        it(@"initialize game state", ^{
            //set up
            [[bzvc should] receive:@selector(viewDidLoad)];
            [[[UIAccelerometer sharedAccelerometer] should] receive:@selector(setUpdateInterval:)  withCountAtLeast:1 arguments:theValue(1.0f/kUpdateFrequency)];
            [[[UIAccelerometer sharedAccelerometer] should] receive:@selector(setDelegate:)  withCountAtLeast:1];
            [[[NSNotificationCenter defaultCenter] should] receive:@selector(addObserver:selector:name:object:) withCountAtLeast:1];
            bzvc.imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Tyra.png"]];
            
            //action
            [bzvc viewDidLoad];
            //validation
            [bzvc.imageView shouldNotBeNil];
            [[theValue(bzvc.gameState) should] equal:theValue(kStateStartGame)];
            [bzvc.gameSession shouldBeNil];
            [bzvc.gamePeerID shouldBeNil];
            [[theValue(bzvc.rotating) should] equal:theValue(NO)];
            [[theValue(bzvc.objectWidth) should] equal:theValue(bzvc.imageView.frame.size.width)];
            [[theValue(bzvc.objectHeight) should] equal:theValue(bzvc.imageView.frame.size.height)];
            [[theValue(bzvc.yPosOfObject) should] equal:theValue(bzvc.imageView.frame.origin.y)];
            [[theValue(bzvc.xPosOfObject) should] equal:theValue(bzvc.imageView.frame.origin.x)];
            [[theValue(bzvc.isThrowing) should] equal:theValue(NO)];
            [[theValue(bzvc.lastAccelerometerUpdateAction) should] equal:theValue(0)];
            [theValue(bzvc.gameUniqueId) shouldNotBeNil];
            
        });
    });
    
    context(@"startPicker", ^{
        it(@"should start the peer picking process", ^{
            //setup
            id mockPicker = [KWMock mockForClass:[GKPeerPickerController class]];
            [[bzvc should] receive:@selector(getPeerPicker) andReturn:mockPicker withCount:1];
            [[mockPicker should] receive:@selector(setDelegate:) withCount:1];
            [[mockPicker should] receive:@selector(show) withCount:1];
            //test
            [bzvc startPicker];
            //validation
            [[theValue(bzvc.gameState) should] equal:theValue(kStatePicker)];
        });
    });
    
    context(@"setGameState", ^{
       it(@"should reset game properties if newState = kStateStartGame", ^{
           bzvc.gameSession = [KWMock mockForClass:[GKSession class]];
           [bzvc.gameSession shouldNotBeNil];
           [[bzvc should] receive:@selector(invalidateSession:) withCount:1];
           [[bzvc.gameSession should] receive:@selector(disconnectFromAllPeers) withCount:1];
           [[bzvc.gameSession should] receive:@selector(setDataReceiveHandler:withContext:) withCount:1];
           [[bzvc.gameSession should] receive:@selector(setAvailable:) withCount:1];
           [[bzvc.gameSession should] receive:@selector(setDelegate:) withCount:1];
           [bzvc setGameState:kStateStartGame];
           [bzvc.gameSession shouldBeNil];
       });
    });
    
    context(@"PeerPicker delegate methods", ^{
        context(@"peerPickerControllerForConnectionTypes", ^{
            it(@"should create and return a game sesstion", ^{
                id mockPicker = [KWMock mockForClass:[GKPeerPickerController class]];
                [[bzvc should] receive:@selector(getSession) withCount:1];
                [bzvc peerPickerController:mockPicker sessionForConnectionType:0];
            });
        });
        context(@"peerPickerControllerDidConnectPeerToSession", ^{
            it(@"should start the session and send coin toss packet", ^{
                //setup
                id mockSession = [KWMock mockForClass:[GKSession class]];
                id mockPicker = [KWMock mockForClass:[GKPeerPickerController class]];
                [[mockSession should] receive:@selector(setDelegate:) withCount:1];
                [[mockSession should] receive:@selector(setDataReceiveHandler:withContext:)];
                [[mockPicker should] receive:@selector(dismiss) withCount:1];
                [[mockPicker should] receive:@selector(setDelegate:) withCount:1];
                [[mockSession should] receive:@selector(sendData:toPeers:withDataMode:error:) withCount:1];
                
                NSString* peerID = @"tyra";
                //action
                [bzvc peerPickerController:mockPicker didConnectPeer:peerID toSession:mockSession];
                //validation
                [[bzvc.gamePeerID should] equal:peerID];
                [[bzvc.gameSession should] equal:mockSession];
                [[theValue(bzvc.gameState) should] equal:theValue(kStateMultiplayerCoinToss)];
            });
        });
    });
});

SPEC_END
