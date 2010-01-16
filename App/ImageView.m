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
//    CGImageRelease(_image);
    [super dealloc];
}

- (void)drawRect:(NSRect)dirtyRect;
{
    if (!_image) {
        [[NSColor blueColor] set];
        NSRectFill([self bounds]);
        return;
    }

#if 0
    CGContextRef ctx = [[NSGraphicsContext currentContext] graphicsPort];
    CGContextDrawImage(ctx, [self bounds], _image);
#endif
    
#if 1
    CGContextRef ctx = [[NSGraphicsContext currentContext] graphicsPort];
    CIContext *ciCtx = [CIContext contextWithCGContext:ctx options:nil];
    [ciCtx drawImage:_image inRect:[self bounds] fromRect:[_image extent]];
#endif
    
#if 0
    NSSize size = [_image size];
    [_image drawInRect:[self bounds] fromRect:NSMakeRect(0, 0, size.width, size.height) operation:NSCompositeSourceOver fraction:1.0];
#endif
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

#if 0
- (CGImageRef)image;
{
    return _image;
}
- (void)setImage:(CGImageRef)image;
{
//    NSLog(@"setting image %@", image);
    if (_image == image)
        return;
    
    CGImageRelease(_image);
    CFRetain(image);
    _image = image;
    [self setNeedsDisplay:YES];
}
#endif

@end
