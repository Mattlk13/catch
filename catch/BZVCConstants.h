//
//  BZVCConstants.h
//  catch
//
//  Created by Glenna Buford on 9/10/12.
//  Copyright (c) 2012 Blazing Cloud, Inc. All rights reserved.
//

#define RADIANS(degrees) ((degrees * (CGFloat)M_PI) / 180.0f)
#define kUpdateFrequency 30.0f

#define kCatchSessionID @"gkcatch"

//set different thresholds for different devices

#define kYAccelerationThreshold 0.05f
#define kXAccelerationThreshold 1.0f

//imageView position off screen
#define kXPosOffScreen 700.0f
#define kYPosOffScreen -500.0f

//Network tokens to know what state we are in
typedef enum {
    kNetworkStateCoinToss = 0,
    kNetworkStateGamePlay = 1,
} networkStates;

//Network packet size
#define kMaxGamePacketSize 1024

typedef enum {
    kStateStartGame = 0,
    kStatePicker = 1,
    kStateMultiplayerCoinToss = 2, //Who will have the "ball" first
    kStateMultiplayer = 3,
    kStateMultiplayerReconnect = 4,
} gameStates;
