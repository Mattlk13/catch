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
#define kUpdateFrequency 60.0f

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
}

- (void)viewDidUnload
{
    [self setImageView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (IBAction)spinImage:(id)sender {
    if (self.rotating) {
        self.rotating = NO;
        
        [[self.imageView layer] removeAllAnimations];
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
@end
