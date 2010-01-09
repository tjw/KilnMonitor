//
//  ImageView.h
//  KilnMonitor
//
//  Created by Timothy J. Wood on 1/8/10.
//  Copyright 2010 The Omni Group. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ImageView : NSView
{
@private
    CGImageRef _image;
}

//@property(retain,nonatomic) CIImage *image;
- (CGImageRef)image;
- (void)setImage:(CGImageRef)image;

@end
