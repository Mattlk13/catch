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

@interface BZViewController ()

@property (nonatomic, readwrite) BOOL rotating;

@end

@implementation BZViewController
@synthesize imageView, rotating;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    [[self view] setBackgroundColor:[UIColor purpleColor]];
    self.rotating = NO;
    
    [[UIAccelerometer sharedAccelerometer] setUpdateInterval:1.0f/kUpdateFrequency];
    [[UIAccelerometer sharedAccelerometer] setDelegate:self];
}

- (void)viewDidUnload
{
    [self setImageView:nil];
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
        [rotationAnimation setDuration:3.0f];
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
//    NSLog(@"Acceleration x: %f, y: %f, z: %f", acceleration.x, acceleration.y, acceleration.z);
    if (!isThrowing && acceleration.x > 1.0f) {
        [self startSpinImage:YES];
        CGFloat xPosFrom = self.imageView.frame.origin.x;
        CGFloat xPosTo = 700.0f;
        
        CGFloat yPosFrom = self.imageView.frame.origin.y;
        CGFloat yPosTo = -500.0f;
        
        CGFloat width = self.imageView.frame.size.width;
        CGFloat height = self.imageView.frame.size.height;
        
        [UIView animateWithDuration:5.0f animations:^{
            isThrowing = YES;
            [self.imageView setFrame:CGRectMake(xPosTo, yPosTo, width, height)];
        } completion:^(BOOL finished) {
            //Bring Tyra back to the screen until we are connected to another player
            [UIView animateWithDuration:5.0f animations:^{
                [self.imageView setFrame:CGRectMake(xPosFrom, yPosFrom, width, height)];
            } completion:^(BOOL finished) {
                isThrowing = NO;
                [self stopSpinImage];
            }];
        }];
    }
}

@end
