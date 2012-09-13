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

typedef enum {
    kStateStartGame,
    kStatePicker,
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

#pragma mark -
#pragma mark Accelerometer delegates

-(void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration
{
    //Throw Tyra off the screen
    static BOOL isThrowing = NO;
    CGFloat accelX = acceleration.x;
    CGFloat accelY = acceleration.y;
//    NSLog(@"Acceleration x: %f, y: %f, z: %f", acceleration.x, acceleration.y, acceleration.z);
    if (!isThrowing && accelX > 2.0f && accelY > 1.0f) {
        [self startSpinImage:YES];
        CGFloat xPosFrom = self.imageView.frame.origin.x;
        CGFloat xPosTo = 700.0f;
        
        CGFloat yPosFrom = self.imageView.frame.origin.y;
        CGFloat yPosTo = -500.0f;
        
        CGFloat width = self.imageView.frame.size.width;
        CGFloat height = self.imageView.frame.size.height;
        
        [UIView animateWithDuration:accelX animations:^{
            isThrowing = YES;
            [self.imageView setFrame:CGRectMake(xPosTo, yPosTo, width, height)];
        } completion:^(BOOL finished) {
            //Bring Tyra back to the screen until we are connected to another player
            [UIView animateWithDuration:accelX animations:^{
                [self.imageView setFrame:CGRectMake(xPosFrom, yPosFrom, width, height)];
            } completion:^(BOOL finished) {
                isThrowing = NO;
                [self stopSpinImage];
            }];
        }];
    }
}

#pragma mark -
#pragma mark Send/Receive data methods

- (void)receiveData:(NSData *)data fromPeer:(NSString *)peer inSession:(GKSession *)session context:(void *)context {
    //
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
    self.gameState = kStateMultiplayer;
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
        UIAlertView *alert;
        
        if(self.gameState == kStateMultiplayerReconnect)  {
            alert = [[UIAlertView alloc] initWithTitle:@"Lost Connection" message:message delegate:self cancelButtonTitle:@"End Game" otherButtonTitles:nil];
        }
        else {
            alert = [[UIAlertView alloc] initWithTitle:@"Lost Connection" message:message delegate:self cancelButtonTitle:@"End Game" otherButtonTitles:nil];
        }
           
        [alert show];
        
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
    } else {
        [self.connectButton setTitle:@"Connecting..." forState:UIControlStateNormal];
        [self.connectButton setTitle:@"Connecting..." forState:UIControlStateDisabled];
        self.connectButton.enabled = NO;
    }
    _gameState = newState;
}



@end
