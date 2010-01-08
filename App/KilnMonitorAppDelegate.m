//
//  KilnMonitorAppDelegate.m
//  KilnMonitor
//
//  Created by Timothy J. Wood on 1/8/10.
//  Copyright 2010 The Omni Group. All rights reserved.
//

#import "KilnMonitorAppDelegate.h"

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
@synthesize sourceImage = _sourceImage;
@synthesize sourceImageView = _sourceImageView;
@synthesize resultImageView = _resultImageView;

+ (NSSet *)keyPathsForValuesAffectingResultImage;
{
    return [NSSet setWithObject:@"sourceImage"];
}
- (NSImage *)resultImage;
{
    if (!_sourceImage)
        return nil;
    
    CIImage *sourceCIImage;
    {
        CGImageRef sourceImageRef = [_sourceImage CGImageForProposedRect:NULL context:nil hints:nil];
        sourceCIImage = [[CIImage alloc] initWithCGImage:sourceImageRef];
        CGImageRelease(sourceImageRef);
    }
    
    CIImage *resultCIImage;
    {
        CIFilter *blurFilter = [CIFilter filterWithName:@"CIBoxBlur"];
        [blurFilter setDefaults];
        
        [blurFilter setValue:[NSNumber numberWithDouble:8.0f] forKey:@"inputRadius"];
        [blurFilter setValue:sourceCIImage forKey:@"inputImage"];
        
        CIImage *blurImage = [blurFilter valueForKey:@"outputImage"];
        
        CIFilter *detectGreenFilter = [[CIFilter alloc] init];
        CISampler *blurSampler = [CISampler samplerWithImage:blurImage];
        CIImage *greenDetectImage = [detectGreenFilter apply:_detectByGreenKernel, blurSampler, kCIApplyOptionDefinition, [blurImage definition], nil];

        NSLog(@"greenDetectImage = %@", greenDetectImage);
        [detectGreenFilter release];
        
        resultCIImage = greenDetectImage;
    }
    
    NSImage *resultImage;
    {
        NSCIImageRep *ciImageRep = [[NSCIImageRep alloc] initWithCIImage:resultCIImage];
        [resultCIImage release];
    
        resultImage = [[NSImage alloc] initWithSize:[_sourceImage size]];
        [resultImage addRepresentation:ciImageRep];
        [ciImageRep release];
    }
    
    return resultImage;
}

@end
