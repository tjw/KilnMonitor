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
    
    NSArray *_availableCaptureDevices;
    QTCaptureDevice *_selectedCaptureDevice;
    NSArrayController *_captureDeviceArrayController;
    QTCaptureView *_captureView;

    ImageView *_resultImageView;
}

@property (assign) IBOutlet NSWindow *window;
@property (retain) IBOutlet ImageView *resultImageView;

@property (retain) IBOutlet NSArrayController *captureDeviceArrayController;
@property (retain) IBOutlet QTCaptureView *captureView;

@end
