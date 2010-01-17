//
//  Bitmap.m
//  KilnMonitor
//
//  Created by Timothy J. Wood on 1/16/10.
//  Copyright 2010 The Omni Group. All rights reserved.
//

#import "Bitmap.h"

Bitmap *BitmapCreateWithCIImage(CIImage *image)
{
    NSCAssert(image, @"image required");
    
    Bitmap *bitmap = calloc(1, sizeof(*bitmap));
    
    NSRect imageExtent = [image extent];
    NSCAssert(NSEqualRects(imageExtent, NSIntegralRect(imageExtent)), @"image should be pixel aligned");
    bitmap->width = NSWidth(imageExtent);
    bitmap->height = NSHeight(imageExtent);
    bitmap->pixels = calloc(bitmap->width * bitmap->height, sizeof(*bitmap->pixels));
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGBLinear);
    CGContextRef bitmapContext = CGBitmapContextCreate(bitmap->pixels, bitmap->width, bitmap->height, 8/*bpc*/, 4*bitmap->width/*bytesPerRow*/, colorSpace, kCGImageAlphaPremultipliedFirst);
    
    NSDictionary *options = [[NSDictionary alloc] initWithObjectsAndKeys:(id)colorSpace, kCIContextOutputColorSpace, nil];
    CGColorSpaceRelease(colorSpace);
    
    CIContext *ciContext = [CIContext contextWithCGContext:bitmapContext options:options];
    [options release];
    
    [ciContext drawImage:image atPoint:NSZeroPoint fromRect:imageExtent];
    CGContextFlush(bitmapContext);
    CGContextRelease(bitmapContext);
    
    return bitmap;
}

void BitmapDestroy(Bitmap *bitmap)
{
    free(bitmap->pixels);
    free(bitmap);
}

CGImageRef BitmapCopyImage(Bitmap *bitmap)
{
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL/*info*/,
                                                              bitmap->pixels, sizeof(*bitmap->pixels) * bitmap->width * bitmap->height,
                                                              NULL /*releaseData*/);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGBLinear);
    CGImageRef image = CGImageCreate(bitmap->width, bitmap->height,
                                     8/*bitsPerComponent*/, 32/*bitsPerPixel*/, 4*bitmap->width/*bytesPerRow*/,
                                     colorSpace, kCGImageAlphaPremultipliedFirst, provider,
                                     NULL/*decode*/, false/*shouldInterpolate*/,
                                     kCGRenderingIntentDefault);
    CGColorSpaceRelease(colorSpace);
    
    return image;
}

BOOL BitmapWritePNG(Bitmap *bitmap, NSURL *url)
{
    CGImageRef imageRef = BitmapCopyImage(bitmap);
    
    CGImageDestinationRef dest = CGImageDestinationCreateWithURL((CFURLRef)url, kUTTypePNG, 1, NULL);
    if (!dest)
	return NO;
    
    CGImageDestinationAddImage(dest, imageRef, NULL);
    CFRelease(imageRef);
    
    BOOL result = CGImageDestinationFinalize(dest) ? YES : NO; // bool -> BOOL, just in case.
    CFRelease(dest);
    return result;
}
