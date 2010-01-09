//
//  KilnMonitorAppDelegate.h
//  KilnMonitor
//
//  Created by Timothy J. Wood on 1/8/10.
//  Copyright 2010 The Omni Group. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface KilnMonitorAppDelegate : NSObject <NSApplicationDelegate> {
    NSWindow *_window;
    
    NSImage *_sourceImage;
    NSImageView *_sourceImageView;
    
    NSImageView *_resultImageView;
    
    CIKernel *_detectByGreenKernel;
    
    NSArray *_availableCaptureDevices;
    QTCaptureDevice *_selectedCaptureDevice;
    NSArrayController *_captureDeviceArrayController;
    
    QTCaptureView *_captureView;
    CIImage *_capturedImage;
    NSImage *_resultImage;
}

@property (assign) IBOutlet NSWindow *window;
@property (retain) IBOutlet NSImageView *sourceImageView;
@property (retain) IBOutlet NSImageView *resultImageView;
@property (copy) NSImage *sourceImage;

@property (retain) IBOutlet NSArrayController *captureDeviceArrayController;
@property (retain) IBOutlet QTCaptureView *captureView;
@property (readonly) NSImage *resultImage;

@end
