//
//  BZViewController.h
//  catch
//
//  Created by Glenna Buford on 9/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BZViewController : UIViewController <UIAccelerometerDelegate>

@property (strong, nonatomic) IBOutlet UIImageView *imageView;

- (IBAction)spinImage:(id)sender;

@end
