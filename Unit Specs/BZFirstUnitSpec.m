//
//  BZFirstUnitSpec.m
//  catch
//
//  Created by Glenna Buford on 9/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Kiwi.h"

SPEC_BEGIN(FirstUnitSpec)

describe(@"Math", ^{
    it(@"is pretty cool", ^{
        NSUInteger a = 16;
        NSUInteger b = 26;
        [[theValue(a + b) should] equal:theValue(42)];
    });
});

SPEC_END
