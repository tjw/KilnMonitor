//
//  KilnMonitorAppDelegate.h
//  KilnMonitor
//
//  Created by Timothy J. Wood on 1/8/10.
//  Copyright 2010 The Omni Group. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class ImageView;

@interface KilnMonitorAppDelegate : NSObject <NSApplicationDelegate> {
    NSWindow *_window;
    
    CIKernel *_detectByGreenKernel;
    
    NSImageView *_inputImageView;
    NSImage *_inputImage;
    
    ImageView *_resultImageView;
}

@property (assign) IBOutlet NSWindow *window;

@property (retain) IBOutlet NSImageView *inputImageView;
@property (copy) NSImage *inputImage;

@property (retain) IBOutlet ImageView *resultImageView;

@end
