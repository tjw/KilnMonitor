//
//  KilnMonitorAppDelegate.m
//  KilnMonitor
//
//  Created by Timothy J. Wood on 1/8/10.
//  Copyright 2010 The Omni Group. All rights reserved.
//

#import "KilnMonitorAppDelegate.h"

static NSString * const AvailableCaptureDevicesBinding = @"availableCaptureDevices";
static NSString * const SelectedCaptureDeviceBinding = @"selectedCaptureDevice";
static NSString * const CapturedImageBinding = @"capturedImage";
static NSString * const ResultImageBinding = @"resultImage";

@interface KilnMonitorAppDelegate (/*Private*/)
@property(copy) NSArray *availableCaptureDevices;
@property(retain,nonatomic) QTCaptureDevice *selectedCaptureDevice;
@property(retain) CIImage *capturedImage;
- (NSImage *)_newResultImage;
@end

@implementation KilnMonitorAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification;
{
    NSString *kernelPath = [[NSBundle mainBundle] pathForResource:@"DetectByGreen" ofType:@"cikernel"];
    NSAssert(kernelPath != nil, @"Kernel source file not found");

    NSError *error = nil;
    NSString *kernelSource = [NSString stringWithContentsOfFile:kernelPath encoding:NSUTF8StringEncoding error:&error];
    if (!kernelSource)
        [NSApp presentError:error];
    else {
        NSArray *kernels = [CIKernel kernelsWithString:kernelSource];
        NSAssert([kernels count] == 1, @"Expected exactly one kernel.");
        
        _detectByGreenKernel = [[kernels lastObject] retain];
    }
    
    self.availableCaptureDevices = [[QTCaptureDevice inputDevicesWithMediaType:QTMediaTypeVideo] retain];
    NSLog(@"_availableCaptureDevices = %@", _availableCaptureDevices);
}

@synthesize window = _window;
@synthesize sourceImage = _sourceImage;
@synthesize sourceImageView = _sourceImageView;
@synthesize resultImageView = _resultImageView;
@synthesize capturedImage = _capturedImage;
@synthesize resultImage = _resultImage;

// Making -resultImage be derived property crashes in NSImageView with a zombie; maybe it calls the accessor w/in an NSAutoreleasePool, not expecting it to go away.
- (void)setCapturedImage:(CIImage *)capturedImage;
{
    if (_capturedImage == capturedImage)
        return;
    
    [self willChangeValueForKey:ResultImageBinding];
    [_capturedImage release];
    _capturedImage = [capturedImage retain];
    [_resultImage release];
    _resultImage = [self _newResultImage];
    [self didChangeValueForKey:ResultImageBinding];
}

@synthesize availableCaptureDevices = _availableCaptureDevices;
@synthesize captureDeviceArrayController = _captureDeviceArrayController;

@synthesize selectedCaptureDevice = _selectedCaptureDevice;
- (void)setSelectedCaptureDevice:(QTCaptureDevice *)device;
{
    if (_selectedCaptureDevice == device)
        return;

    // close any open session and stop using the device.
    [[_captureView captureSession] stopRunning];
    [_selectedCaptureDevice close];
    
    [self willChangeValueForKey:SelectedCaptureDeviceBinding];
    [_selectedCaptureDevice release];
    _selectedCaptureDevice = [device retain];
    [self didChangeValueForKey:SelectedCaptureDeviceBinding];
    
    NSLog(@"_selectedCaptureDevice = %p %@", _selectedCaptureDevice);
    
    NSLog(@"captureView.session = %@", [_captureView captureSession]);
    NSLog(@"captureView.availableVideoPreviewConnections = %@", [_captureView availableVideoPreviewConnections]);
    
    QTCaptureSession *captureSession = nil;
    
    if (_selectedCaptureDevice) {
        NSError *error = nil;

        if (![_selectedCaptureDevice open:&error]) {
            NSLog(@"Unable to open device %@", error);
            return;
        }
        NSLog(@"opened");
        
        captureSession = [[[QTCaptureSession alloc] init] autorelease];
        QTCaptureDeviceInput *captureVideoDeviceInput = [[[QTCaptureDeviceInput alloc] initWithDevice:_selectedCaptureDevice] autorelease];
        
        if (![captureSession addInput:captureVideoDeviceInput error:&error]) {
            NSLog(@"error adding input %@", error);
            return;
        }
        NSLog(@"input added");
    }
    
    [_captureView setCaptureSession:captureSession];
    
    if (captureSession) {
        [captureSession startRunning];
        NSLog(@"started");
    }
}

@synthesize captureView = _captureView;

#pragma mark -
#pragma mark QTCaptureView delegate

- (CIImage *)view:(QTCaptureView *)view willDisplayImage:(CIImage *)image;
{
    self.capturedImage = image;
    return nil; // use the passed in image
}

#pragma mark -
#pragma mark Private

- (NSImage *)_newResultImage;
{
    if (!_capturedImage)
        return nil;
    
#if 0
    CIImage *sourceCIImage;
    {
        CGImageRef sourceImageRef = [_sourceImage CGImageForProposedRect:NULL context:[window graphicsContext] hints:nil];
        sourceCIImage = [[[CIImage alloc] initWithCGImage:sourceImageRef] autorelease];
        CGImageRelease(sourceImageRef);
    }
#endif
    //    CIImage *sourceCIImage = _capturedImage;
    
    CIImage *resultCIImage;
    {
        CIFilter *blurFilter = [CIFilter filterWithName:@"CIBoxBlur"];
        [blurFilter setDefaults];
        
        [blurFilter setValue:[NSNumber numberWithDouble:8.0f] forKey:@"inputRadius"];
        [blurFilter setValue:_capturedImage forKey:@"inputImage"];
        
        CIImage *blurImage = [blurFilter valueForKey:@"outputImage"];
        
        CIFilter *detectGreenFilter = [[CIFilter alloc] init];
        CISampler *blurSampler = [CISampler samplerWithImage:blurImage];
        CIImage *greenDetectImage = [detectGreenFilter apply:_detectByGreenKernel, blurSampler, kCIApplyOptionDefinition, [blurImage definition], nil];
        
        //NSLog(@"greenDetectImage = %@", greenDetectImage);
        [detectGreenFilter release];
        
        resultCIImage = greenDetectImage;
    }
    
    NSImage *resultImage;
    {
        NSCIImageRep *ciImageRep = [[NSCIImageRep alloc] initWithCIImage:resultCIImage];
        
        resultImage = [[NSImage alloc] initWithSize:[ciImageRep size]]; // LEAK
        [resultImage addRepresentation:ciImageRep];
        [ciImageRep release];
    }
    
    return resultImage;
}

@end
