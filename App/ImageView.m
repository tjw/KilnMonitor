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
    CGImageRelease(_image);
    [super dealloc];
}

- (void)drawRect:(NSRect)dirtyRect;
{
    if (!_image) {
        [[NSColor blueColor] set];
        NSRectFill([self bounds]);
        return;
    }

    CGContextRef ctx = [[NSGraphicsContext currentContext] graphicsPort];
    CGContextDrawImage(ctx, [self bounds], _image);
#if 0
    CGContextRef ctx = [[NSGraphicsContext currentContext] graphicsPort];
    CIContext *ciCtx = [CIContext contextWithCGContext:ctx options:nil];
    [ciCtx drawImage:_image inRect:[self bounds] fromRect:[_image extent]];
#endif
    
#if 0
    NSSize size = [_image size];
    [_image drawInRect:[self bounds] fromRect:NSMakeRect(0, 0, size.width, size.height) operation:NSCompositeSourceOver fraction:1.0];
#endif
}

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

@end
