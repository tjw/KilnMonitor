//
//  KilnMonitorAppDelegate.m
//  KilnMonitor
//
//  Created by Timothy J. Wood on 1/8/10.
//  Copyright 2010 The Omni Group. All rights reserved.
//

#import "KilnMonitorAppDelegate.h"

#import "ImageView.h"

static NSString * const ResultImageBinding = @"resultImage";

@interface KilnMonitorAppDelegate (/*Private*/)
- (void)_receivedInputImage:(CIImage *)image;
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

- (void)_receivedInputImage:(CIImage *)image;
{
    CGImageRef filteredImage = [self _makeResultImage:image];
    // This is called in a background thread. Don't poke the view system from back here.
    dispatch_async(dispatch_get_main_queue(), ^{
        _resultImageView.image = filteredImage;
        CGImageRelease(filteredImage);
    });
}

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
