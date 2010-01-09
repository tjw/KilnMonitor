//
//  KilnMonitorAppDelegate.m
//  KilnMonitor
//
//  Created by Timothy J. Wood on 1/8/10.
//  Copyright 2010 The Omni Group. All rights reserved.
//

#import "KilnMonitorAppDelegate.h"

#import "ImageView.h"

static NSString * const AvailableCaptureDevicesBinding = @"availableCaptureDevices";
static NSString * const SelectedCaptureDeviceBinding = @"selectedCaptureDevice";
static NSString * const CapturedImageBinding = @"capturedImage";
static NSString * const ResultImageBinding = @"resultImage";

@interface KilnMonitorAppDelegate (/*Private*/)
@property(copy) NSArray *availableCaptureDevices;
@property(retain,nonatomic) QTCaptureDevice *selectedCaptureDevice;
- (CGImageRef)_makeResultImage:(CIImage *)sourceImage;
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
@synthesize resultImageView = _resultImageView;

@synthesize availableCaptureDevices = _availableCaptureDevices;
@synthesize captureDeviceArrayController = _captureDeviceArrayController;

@synthesize selectedCaptureDevice = _selectedCaptureDevice;
- (void)setSelectedCaptureDevice:(QTCaptureDevice *)device;
{
    if (_selectedCaptureDevice == device)
        return;

    NSLog(@"device.uniqueID = %@", device.uniqueID);
    NSLog(@"device.modelUniqueID = %@", device.modelUniqueID);
    NSLog(@"device.localizedDisplayName = %@", device.localizedDisplayName);
    NSLog(@"device.deviceAttributes = %@", device.deviceAttributes);

    for (QTFormatDescription *desc in device.formatDescriptions) {
        NSLog(@"format %@ %@", [desc mediaType], [desc localizedFormatSummary]);
        NSLog(@"%@", [desc formatDescriptionAttributes]);
    }


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
    CGImageRef filteredImage = [self _makeResultImage:image];
    // This is called in a background thread. Don't poke the view system from back here.
    dispatch_async(dispatch_get_main_queue(), ^{
        _resultImageView.image = filteredImage;
        CGImageRelease(filteredImage);
    });
    return nil; // use the passed in image
}

#pragma mark -
#pragma mark Private

- (CGImageRef)_makeResultImage:(CIImage *)sourceImage;
{
    if (!sourceImage)
        return nil;
    
#if 0
    CIImage *sourceCIImage;
    {
        CGImageRef sourceImageRef = [_sourceImage CGImageForProposedRect:NULL context:[_window graphicsContext] hints:nil];
        sourceCIImage = [[[CIImage alloc] initWithCGImage:sourceImageRef] autorelease];
        CGImageRelease(sourceImageRef);
    }
#endif
    //    CIImage *sourceCIImage = sourceImage;
    
    CIImage *resultCIImage;
    {
        CIFilter *blurFilter = [CIFilter filterWithName:@"CIBoxBlur"];
        [blurFilter setDefaults];
        
        [blurFilter setValue:[NSNumber numberWithDouble:8.0f] forKey:@"inputRadius"];
        [blurFilter setValue:sourceImage forKey:@"inputImage"];
        
        CIImage *blurImage = [blurFilter valueForKey:@"outputImage"];
        
        CIFilter *detectGreenFilter = [[CIFilter alloc] init];
        CISampler *blurSampler = [CISampler samplerWithImage:blurImage];
        CIImage *greenDetectImage = [detectGreenFilter apply:_detectByGreenKernel, blurSampler, kCIApplyOptionDefinition, [blurImage definition], nil];
        
        //NSLog(@"greenDetectImage = %@", greenDetectImage);
        [detectGreenFilter release];
        
        resultCIImage = greenDetectImage;
    }

    {
        // The resultCIImage is a recipe for how to build the image, and if we stick this in the actual result NSImage (via NSCIImage), we get an error when drawing it.  My guess is that some portion of the recipe has been invalidated by the time this happens (some CoreVideo buffer maybe, based on where I hit the CG error).
        // So, flatten the image immediately. Probably non-optimal, possibly a bug in CI/QT/CV/CG somewhere.

#if 0        
        NSCIImageRep *ciImageRep = [[NSCIImageRep alloc] initWithCIImage:resultCIImage];
        
        resultImage = [[NSImage alloc] initWithSize:[ciImageRep size]]; // LEAK
        [resultImage addRepresentation:ciImageRep];
        [ciImageRep release];
#endif
        
        CIContext *ciContext = [CIContext contextWithCGContext:[[_window graphicsContext] graphicsPort] options:nil];
        CGRect sourceRect = [resultCIImage extent];
        CGImageRef resultCGImage = [ciContext createCGImage:resultCIImage fromRect:sourceRect];
        
        return resultCGImage;
//        CIImage *resultImage = [CIImage imageWithCGImage:resultCGImage];
//        CGImageRelease(resultCGImage);
        
        //NSLog(@"resultImage = %@", resultImage);
//        return resultImage;
    }
}

@end
