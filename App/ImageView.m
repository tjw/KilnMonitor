//
//  ImageView.m
//  KilnMonitor
//
//  Created by Timothy J. Wood on 1/8/10.
//  Copyright 2010 The Omni Group. All rights reserved.
//

#import "ImageView.h"


@implementation ImageView

- (void)dealloc;
{
    [_image release];
    [super dealloc];
}

- (void)drawRect:(NSRect)dirtyRect;
{
    if (!_image) {
        [[NSColor blueColor] set];
        NSRectFill([self bounds]);
        return;
    }

    NSRect bounds = [self bounds];
    NSRect extent = [_image extent];
    
    // Scale to fit the bounds and preserve the aspect ratio
    CGFloat scale = MIN(NSWidth(bounds)/NSWidth(extent), NSHeight(bounds)/NSHeight(extent));

    NSRect destRect;
    destRect.size.width = scale * NSWidth(extent);
    destRect.size.height = scale * NSHeight(extent);
    destRect.origin.x = (NSWidth(bounds) - destRect.size.width)/2.0;
    destRect.origin.y = (NSHeight(bounds) - destRect.size.height)/2.0;

    CGContextRef ctx = [[NSGraphicsContext currentContext] graphicsPort];
    CIContext *ciCtx = [CIContext contextWithCGContext:ctx options:nil];
    [ciCtx drawImage:_image inRect:destRect fromRect:extent];
}

@synthesize image = _image;
- (void)setImage:(CIImage *)image;
{
    if (_image == image)
        return;
    
    [_image release];
    _image = [image retain];
    [self setNeedsDisplay:YES];
}

@end
