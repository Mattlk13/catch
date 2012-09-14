//
//  CoverageFix.m
//
//  This fixes a problem related to an Apple implementation of a core unix api.
//
//  Created by Paul Zabelin on 5/17/12.
//  Copyright (c) 2012 Blazing Cloud, Inc. All rights reserved.
//

// Include this into app target to measure Application Tests code coverage
// Exclude from RELEASE build not to ship with the app
#ifdef DEBUG

@interface CoverageFix : NSObject

FILE* fopen$UNIX2003(const char* filename, const char* mode);
size_t fwrite$UNIX2003(const void* ptr, size_t size, size_t nitems, FILE* stream);

@end

@implementation CoverageFix

FILE* fopen$UNIX2003(const char* filename, const char* mode) {
    return fopen(filename, mode);
}

size_t fwrite$UNIX2003(const void* ptr, size_t size, size_t nitems, FILE* stream) {
    return fwrite(ptr, size, nitems, stream);
}

@end

#endif