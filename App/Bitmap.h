//
//  Bitmap.h
//  KilnMonitor
//
//  Created by Timothy J. Wood on 1/16/10.
//  Copyright 2010 The Omni Group. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef struct {
    uint8_t a, r, g, b;
} Pixel;

typedef struct {
    uint32_t width, height;
    Pixel *pixels;
} Bitmap;

extern Bitmap *BitmapCreateWithCIImage(CIImage *image);
extern void BitmapDestroy(Bitmap *bitmap);
