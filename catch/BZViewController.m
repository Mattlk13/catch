//
//  BZViewController.m
//  catch
//
//  Created by Glenna Buford on 9/10/12.
//  Copyright (c) 2012 Blazing Cloud, Inc. All rights reserved.
//

#import "BZVCConstants.m"
#import "BZViewController.h"
#import <QuartzCore/QuartzCore.h>

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

#pragma mark -
#pragma mark View Stuff

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
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark -
#pragma mark UI

- (void)positionImageOffScreen {
    [self setImageFrameWithX:kXPosOffScreen Y:kYPosOffScreen Width:self.objectWidth andHeight:self.objectHeight];
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

- (void)enableConnectButton:(BOOL)enable {
    self.connectButton.enabled = enable;
}

- (void)setConnectButtonTitleAndEnable:(NSString*)message {
    [self enableConnectButton:YES];
    [self setButtonTitleForAllStates:message];
}

- (void)hideImageView:(BOOL)hide {
    self.imageView.hidden = hide;
}

- (void)positionImageViewAtOriginalPosition {
    [self setImageFrameWithX:self.xPosOfObject Y:self.yPosOfObject Width:self.objectWidth andHeight:self.objectHeight];
}

- (void)setImageFrameWithX:(CGFloat)xPos Y:(CGFloat)yPos Width:(CGFloat)width andHeight:(CGFloat)height {
    [self.imageView setFrame:CGRectMake(xPos, yPos, width, height)];
}

- (void)setButtonTitleForAllStates:(NSString*)title {
    [self.connectButton setTitle:title forState:UIControlStateNormal];
    [self.connectButton setTitle:title forState:UIControlStateDisabled];
    [self.connectButton setTitle:title forState:UIControlStateHighlighted];
    [self.connectButton setTitle:title forState:UIControlStateReserved];
    [self.connectButton setTitle:title forState:UIControlStateSelected];
}

- (IBAction)connectWithGC:(id)sender {
    if (self.gameSession) {
        [self.gameSession disconnectFromAllPeers];
    } else {
        [self startPicker];
    }
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
    [self hideImageView:NO];
    [self positionImageOffScreen];
    [UIView animateWithDuration:2.0f animations:^{
        [self positionImageViewAtOriginalPosition];
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
 
            [UIView animateWithDuration:accelX * 2.0f animations:^{
                self.isThrowing = YES;
                [self positionImageOffScreen];
            } completion:^(BOOL finished) {
                //Bring Tyra back to the screen until we are connected to another player
                if (!self.gameSession) {
                    [self objectComesToScreen];
                } else {
                    NSInteger gameID = self.gameUniqueId;
                    [self sendNetworkPacket:self.gameSession packetID:kNetworkStateGamePlay withData:&gameID ofLength:sizeof(int)];
                }
            }];
        }
    }
}

#pragma mark -
#pragma mark Send/Receive data methods

- (void)receiveData:(NSData *)data fromPeer:(NSString *)peer inSession:(GKSession *)session context:(void *)context {
    
    unsigned char *incomingPacket = (unsigned char *)[data bytes];
    int *pIntData = (int *)&incomingPacket[0];

    int packetID = pIntData[0];
    NSInteger peerGameUniqueId = pIntData[1];
    
    //if CoinToss packet then set which person has Tyra initially
    if (packetID == kNetworkStateCoinToss) {
        if (peerGameUniqueId > self.gameUniqueId) {
            //remove object
            [self hideImageView:YES];
        }
        self.gameState = kStateMultiplayer;
    } else {
    //otherwise, it's just the game of catch
        [self objectComesToScreen];
    }
}

- (void)sendNetworkPacket:(GKSession *)session packetID:(int)packetID withData:(void *)data ofLength:(int)length {
    static unsigned char networkPacket[kMaxGamePacketSize];
    const unsigned int packetHeaderSize = 1 * sizeof(int); // we have one "int" for our header
    
    if(length < (kMaxGamePacketSize - packetHeaderSize)) { // our networkPacket buffer size minus the size of the header info
        int *pIntData = (int *)&networkPacket[0];
        // header info
        pIntData[0] = packetID;
        // copy data in after the header
        memcpy( &networkPacket[packetHeaderSize], data, length );
        
        NSData *packet = [NSData dataWithBytes: networkPacket length: (length+8)];
        
        [self.gameSession sendData:packet toPeers:[NSArray arrayWithObject:self.gamePeerID] withDataMode:GKSendDataReliable error:nil];
    }
    NSLog(@"UH OH");
}

#pragma mark -
#pragma mark Peer Picker

- (GKPeerPickerController*)getPeerPicker {
    return [[GKPeerPickerController alloc] init];
}

-(void)startPicker {
    GKPeerPickerController* picker = [self getPeerPicker];
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
        [self positionImageViewAtOriginalPosition];
        [self hideImageView:NO];
        [self enableConnectButton:YES];
        [self setButtonTitleForAllStates:@"Connect with other players"];
        if(self.gameSession) {
            // invalidate session and release it.
            [self invalidateSession:self.gameSession];
            self.gameSession = nil;
        }
    } else if(newState == kStateMultiplayer)
    {
        [self setButtonTitleForAllStates:@"Connected!"];
        [self enableConnectButton:NO];
    } else if(newState == kStateMultiplayerCoinToss) {
        NSInteger gameID = self.gameUniqueId;
        [self sendNetworkPacket:self.gameSession packetID:kNetworkStateCoinToss withData:&gameID ofLength:sizeof(int)];
    } else {
        [self setButtonTitleForAllStates:@"Connecting..."];
        [self enableConnectButton:NO];
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
