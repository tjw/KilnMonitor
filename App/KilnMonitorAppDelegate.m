//
//  KilnMonitorAppDelegate.m
//  KilnMonitor
//
//  Created by Timothy J. Wood on 1/8/10.
//  Copyright 2010 The Omni Group. All rights reserved.
//

#import "KilnMonitorAppDelegate.h"

#import "ImageView.h"
#import "Bitmap.h"

static NSString * const ResultImageBinding = @"resultImage";

@interface KilnMonitorAppDelegate (/*Private*/)
- (CIKernel *)_loadKernel:(NSString *)name;
- (void)_receivedInputImage:(CIImage *)image;
- (CIImage *)_makeResultImage:(CIImage *)sourceImage;
@end

@implementation KilnMonitorAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification;
{
    _findVeryGreenKernel = [[self _loadKernel:@"FindVeryGreen"] retain];
    _detectByGreenKernel = [[self _loadKernel:@"DetectByGreen"] retain];
}

@synthesize window = _window;
@synthesize inputImageView = _inputImageView;
@synthesize resultImageView = _resultImageView;

@synthesize inputImage = _inputImage;
- (void)setInputImage:(NSImage *)inputImage;
{
    if (_inputImage == inputImage)
        return;
    
    [_inputImage release];
    _inputImage = [inputImage copy];
    
    NSLog(@"_inputImage = %@", _inputImage);
    
    CIImage *ciInputImage = nil;
    if (_inputImage) {
        CGImageRef inputImageRef = [_inputImage CGImageForProposedRect:NULL context:[_window graphicsContext] hints:nil];
        if (inputImageRef)
            ciInputImage = [[CIImage alloc] initWithCGImage:inputImageRef];
    }
    [self _receivedInputImage:ciInputImage];
    [ciInputImage release];
}

#pragma mark -
#pragma mark Private

- (CIKernel *)_loadKernel:(NSString *)name;
{
    NSString *kernelPath = [[NSBundle mainBundle] pathForResource:name ofType:@"cikernel"];
    NSAssert(kernelPath != nil, @"Kernel source file not found");
    
    NSError *error = nil;
    NSString *kernelSource = [NSString stringWithContentsOfFile:kernelPath encoding:NSUTF8StringEncoding error:&error];
    if (!kernelSource) {
        [NSApp presentError:error];
        return nil;
    } else {
        NSArray *kernels = [CIKernel kernelsWithString:kernelSource];
        NSAssert([kernels count] == 1, @"Expected exactly one kernel.");
        
        return [kernels lastObject];
    }
}

- (void)_receivedInputImage:(CIImage *)image;
{
    CIImage *filteredImage = [self _makeResultImage:image];
    // This is called in a background thread. Don't poke the view system from back here.
    dispatch_async(dispatch_get_main_queue(), ^{
        _resultImageView.image = filteredImage;
    });
}

- (CIImage *)_makeResultImage:(CIImage *)sourceImage;
{
    if (!sourceImage)
        return nil;
    
    CIImage *resultCIImage;
    {
        CIFilter *detectGreenFilter = [[CIFilter alloc] init];
        CISampler *sourceSampler = [CISampler samplerWithImage:sourceImage];
        CIImage *greenDetectImage = [detectGreenFilter apply:_findVeryGreenKernel, sourceSampler, kCIApplyOptionDefinition, [sourceImage definition], nil];
        
        [detectGreenFilter release];
        
        resultCIImage = greenDetectImage;
    }

    {
        Bitmap *bitmap = BitmapCreateWithCIImage(resultCIImage);
        BitmapDestroy(bitmap);
    }
    
    return resultCIImage;
}

@end
