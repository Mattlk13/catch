//
//  BZViewController.m
//  catch
//
//  Created by Glenna Buford on 9/10/12.
//  Copyright (c) 2012 Blazing Cloud, Inc. All rights reserved.
//

#import "BZViewController.h"
#import <QuartzCore/QuartzCore.h>

#define RADIANS(degrees) ((degrees * (CGFloat)M_PI) / 180.0f)
#define kUpdateFrequency 30.0f

#define kCatchSessionID @"gkcatch"

//set different thresholds for different devices

#define kYAccelerationThreshold 0.05f
#define kXAccelerationThreshold 1.0f

typedef enum {
    kStateStartGame,
    kStatePicker,
    kStateMultiplayerCoinToss, //Who will have the "ball" first
    kStateMultiplayer,
    kStateMultiplayerReconnect,
} gameStates;

@interface BZViewController ()
{

}

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




@end

@implementation BZViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    [[self view] setBackgroundColor:[UIColor purpleColor]];
    self.rotating = NO;
    self.gamePeerID = nil;
    self.gameSession = nil;
    self.objectWidth = self.imageView.frame.size.width;
    self.objectHeight = self.imageView.frame.size.height;
    self.yPosOfObject = self.imageView.frame.origin.y;
    self.xPosOfObject = self.imageView.frame.origin.x;
    self.isThrowing = NO;
    self.lastAccelerometerUpdateAction = 0;
    
    NSString *uid = (__bridge NSString *)(CFUUIDCreate(NULL));
    self.gameUniqueId = [uid hash];
    
    [[UIAccelerometer sharedAccelerometer] setUpdateInterval:1.0f/kUpdateFrequency];
    [[UIAccelerometer sharedAccelerometer] setDelegate:self];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateButtonHidden:) name:@"UpdateButtonHidden" object:nil];
}

- (void)viewDidUnload
{
    [self setImageView:nil];
    [self setConnectButton:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return NO;
}

#pragma mark -
#pragma mark UI

- (void)stopSpinImage {
    self.rotating = NO;
    [[self.imageView layer] removeAnimationForKey:@"rotate"];
}

- (void)startSpinImage:(BOOL)force {
    if (force && self.rotating) {
        [self stopSpinImage];
        [self spinImage:nil];
    } else {
        [self spinImage:nil];
    }
}

- (void)updateButtonHidden:(NSNotification *)note {
    self.connectButton.hidden = [[note.userInfo objectForKey:@"hidden"] boolValue];
}

- (IBAction)connectWithGC:(id)sender {
    [self startPicker];
}

- (IBAction)spinImage:(id)sender {
    if (self.rotating) {
        [self stopSpinImage];
        //Stop Transform
    } else {
        self.rotating = YES;
        //Start Transform
        CABasicAnimation *rotationAnimation = [CABasicAnimation
                                               animationWithKeyPath:@"transform.rotation.z"];
        
        [rotationAnimation setFromValue:[NSNumber numberWithFloat:RADIANS(0)]];
        [rotationAnimation setToValue:[NSNumber numberWithFloat:RADIANS(360)]];
        [rotationAnimation setDuration:2.0f];
        [rotationAnimation setRepeatCount:10000];
        
        [[self.imageView layer] addAnimation:rotationAnimation forKey:@"rotate"];
    }
}

- (void)objectComesToScreen {
    [self.imageView setFrame:CGRectMake(700.0f, -500.0f, self.objectWidth, self.objectHeight)];
    [UIView animateWithDuration:2.0f animations:^{
        [self.imageView setFrame:CGRectMake(self.xPosOfObject, self.yPosOfObject, self.objectWidth, self.objectHeight)];
    } completion:^(BOOL finished) {
        [self stopSpinImage];
    }];
    self.isThrowing = NO;
}

#pragma mark -
#pragma mark Accelerometer delegates

-(void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration
{
    if ((double)acceleration.timestamp - self.lastAccelerometerUpdateAction > 1.0f) {
        self.lastAccelerometerUpdateAction = (double)acceleration.timestamp;
        //Throw Tyra off the screen
        CGFloat accelX = acceleration.x;
        CGFloat accelY = acceleration.y;
        //    NSLog(@"Acceleration x: %f, y: %f, z: %f", acceleration.x, acceleration.y, acceleration.z);
        if (!self.isThrowing
            && (accelX > kXAccelerationThreshold || accelX < -kXAccelerationThreshold)
            && (accelY > kYAccelerationThreshold || accelY < -kYAccelerationThreshold)) {
            [self startSpinImage:YES];
            CGFloat xPosTo = 700.0f;
            CGFloat yPosTo = -500.0f;
            
            
            
            [UIView animateWithDuration:accelX animations:^{
                self.isThrowing = YES;
                [self.imageView setFrame:CGRectMake(xPosTo, yPosTo, self.objectWidth, self.objectHeight)];
            } completion:^(BOOL finished) {
                //Bring Tyra back to the screen until we are connected to another player
                if (!self.gameSession) {
                    [self objectComesToScreen];
                } else {
                    NSError *error;
                    NSInteger gameID = self.gameUniqueId;
                    NSData *dataToSend = [NSData dataWithBytes:&gameID length:sizeof(gameID)];
                    [self.gameSession sendData:dataToSend toPeers:[NSArray arrayWithObject:self.gamePeerID] withDataMode:GKSendDataReliable error:&error];
                }
            }];
        }
    }
}

#pragma mark -
#pragma mark Send/Receive data methods

- (void)receiveData:(NSData *)data fromPeer:(NSString *)peer inSession:(GKSession *)session context:(void *)context {
    //if CoinToss packet then set which person has Tyra initially
    
    //otherwise, it's just the game of catch
    [self objectComesToScreen];
}

#pragma mark -
#pragma mark Peer Picker

-(void)startPicker {
    GKPeerPickerController* picker = [[GKPeerPickerController alloc] init];
    self.gameState = kStatePicker;          // we're going to do Multiplayer!
    picker.delegate = self;
    [picker show]; // show the Peer Picker
}

#pragma mark -
#pragma mark GKPeerPickerControllerDelegate

- (void)peerPickerControllerDidCancel:(GKPeerPickerController *)picker {
    // Peer Picker automatically dismisses on user cancel. No need to programmatically dismiss.
    
    // autorelease the picker.
    picker.delegate = nil;
    
    // invalidate and release game session if one is around.
    if(self.gameSession != nil) {
        [self invalidateSession:self.gameSession];
        self.gameSession = nil;
    }
    
    // go back to start mode
    self.gameState = kStateStartGame;
}

- (GKSession *)peerPickerController:(GKPeerPickerController *)picker sessionForConnectionType:(GKPeerPickerConnectionType)type {
    GKSession *session = [[GKSession alloc] initWithSessionID:kCatchSessionID displayName:nil sessionMode:GKSessionModePeer];
    return session; // peer picker retains a reference, so autorelease ours so we don't leak.
}

- (void)peerPickerController:(GKPeerPickerController *)picker didConnectPeer:(NSString *)peerID toSession:(GKSession *)session {
    // Remember the current peer.
    self.gamePeerID = peerID;  // copy
    
    // Make sure we have a reference to the game session and it is set up
    self.gameSession = session; // retain
    self.gameSession.delegate = self;
    [self.gameSession setDataReceiveHandler:self withContext:NULL];
    
    // Done with the Peer Picker so dismiss it.
    [picker dismiss];
    picker.delegate = nil;
    
    // Start Multiplayer game by entering a cointoss state to determine who is server/client.
    self.gameState = kStateMultiplayerCoinToss;
}

#pragma mark -
#pragma mark GKSessionDelegates

- (void)session:(GKSession *)session peer:(NSString *)peerID didChangeState:(GKPeerConnectionState)state {
    if(self.gameState == kStatePicker) {
        return;             // only do stuff if we're in multiplayer, otherwise it is probably for Picker
    }
    
    if(state == GKPeerStateDisconnected) {
        // We've been disconnected from the other peer.
        
        // Update user alert or throw alert if it isn't already up
        NSString *message = [NSString stringWithFormat:@"Could not reconnect with %@.", [session displayNameForPeer:peerID]];
        
        if(self.gameState == kStateMultiplayerReconnect)  {
            self.alert = [[UIAlertView alloc] initWithTitle:@"Lost Connection" message:message delegate:self cancelButtonTitle:@"End Game" otherButtonTitles:nil];
            [session cancelConnectToPeer:self.gamePeerID];
        }
        else {
            self.alert = [[UIAlertView alloc] initWithTitle:@"Lost Connection" message:message delegate:self cancelButtonTitle:@"End Game" otherButtonTitles:nil];
        }
           
        [self.alert show];
        
        // go back to start mode
        self.gameState = kStateStartGame;
    }
}

- (void)session:(GKSession *)session didFailWithError:(NSError *)error {
    
}

- (void)session:(GKSession *)session didReceiveConnectionRequestFromPeer:(NSString *)peerID {
    
}

- (void)session:(GKSession *)session connectionWithPeerFailed:(NSString *)peerID withError:(NSError *)error {
    
}

#pragma mark -
#pragma mark Game Session methods

- (void)invalidateSession:(GKSession *)session {
    if(session != nil) {
        [session disconnectFromAllPeers];
        session.available = NO;
        [session setDataReceiveHandler: nil withContext: NULL];
        session.delegate = nil;
    }
}

#pragma mark -
#pragma mark Custom getters and setters

- (void)setGameState:(NSInteger)newState {
    if(newState == kStateStartGame) {
        self.connectButton.enabled = YES;
        [self.connectButton setTitle:@"Connect with other players" forState:UIControlStateNormal];
        if(self.gameSession) {
            // invalidate session and release it.
            [self invalidateSession:self.gameSession];
            self.gameSession = nil;
        }
    } else if(newState == kStateMultiplayer)
    {
        [self.connectButton setTitle:@"Connected!" forState:UIControlStateNormal];
        [self.connectButton setTitle:@"Connected!" forState:UIControlStateDisabled];
        self.connectButton.enabled = NO;
    } else if(newState == kStateMultiplayerCoinToss) {
        
    } else {
        [self.connectButton setTitle:@"Connecting..." forState:UIControlStateNormal];
        [self.connectButton setTitle:@"Connecting..." forState:UIControlStateDisabled];
        self.connectButton.enabled = NO;
    }
    _gameState = newState;
}

#pragma mark -
#pragma mark UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    // 0 index is "End Game" button
    if(buttonIndex == 0) {
        self.gameState = kStateStartGame;
    }
}

@end
