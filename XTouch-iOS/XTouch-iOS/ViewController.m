//
//  ViewController.m
//  XTouch-iOS
//
//  Created by Keng Kiat Lim on 24/1/15.
//  Copyright (c) 2015 XTouch. All rights reserved.
//

#import "ViewController.h"

@interface ViewController () {
    IBOutlet UIImageView *overlayView;
    AVCaptureVideoPreviewLayer *previewLayer;
}
@end

@implementation ViewController

- (NSArray *)detectRectangles:(CIImage *)image
{
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:CIDetectorAccuracyHigh, CIDetectorAccuracy, nil];
    CIDetector *rectDetector = [CIDetector detectorOfType:CIDetectorTypeRectangle context:nil options:options];
    
    NSArray *rectangles = [rectDetector featuresInImage:image];
    return rectangles;
}

- (UIBezierPath *)createPathFromRect:(CIRectangleFeature *)rect
{
    UIBezierPath *path = [UIBezierPath new];
    // Start at the first corner
    [path moveToPoint:rect.topLeft];
    [path addLineToPoint:rect.topRight];
    [path addLineToPoint:rect.bottomRight];
    [path addLineToPoint:rect.bottomLeft];
    [path addLineToPoint:rect.topLeft];
    
    return path;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view, typically from a nib.
    
    AVCaptureSession *session = [[AVCaptureSession alloc] init];
    session.sessionPreset = AVCaptureSessionPreset352x288;
    
    previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:session];
    previewLayer.frame = imageView.bounds;
    [imageView.layer addSublayer:previewLayer];
    
    NSError *error = nil;
    AVCaptureDevice *device = [self backCamera];
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    if (!input) {
        // Handle the error appropriately.
        NSLog(@"ERROR: trying to open camera: %@", error);
    }
    
    AVCaptureVideoDataOutput *videoDataOutput = [AVCaptureVideoDataOutput new];
    NSDictionary *newSettings =
    @{ (NSString *)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA) };
    videoDataOutput.videoSettings = newSettings;
    
    // discard if the data output queue is blocked (as we process the still image
    [videoDataOutput setAlwaysDiscardsLateVideoFrames:YES];
    
    // create a serial dispatch queue used for the sample buffer delegate as well as when a still image is captured
    // a serial dispatch queue must be used to guarantee that video frames will be delivered in order
    // see the header doc for setSampleBufferDelegate:queue: for more information
    videoDataOutputQueue = dispatch_queue_create("VideoDataOutputQueue", DISPATCH_QUEUE_SERIAL);
    [videoDataOutput setSampleBufferDelegate:self queue:videoDataOutputQueue];
    
    
    if ( [session canAddOutput:videoDataOutput] )
        [session addOutput:videoDataOutput];
    
    [session addInput:input];
    [session startRunning];
}

- (AVCaptureDevice *)backCamera {
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if ([device position] == AVCaptureDevicePositionBack) {
            return device;
        }
    }
    return nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    
    if(interfaceOrientation == UIInterfaceOrientationLandscapeRight)
    {
        previewLayer.connection.videoOrientation = AVCaptureVideoOrientationLandscapeRight;
    }
    
    // and so on for other orientations
    
    return ((interfaceOrientation == UIInterfaceOrientationLandscapeRight));
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection
{
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CFDictionaryRef attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault, sampleBuffer, kCMAttachmentMode_ShouldPropagate);
    CIImage *ciImage = [[CIImage alloc] initWithCVPixelBuffer:pixelBuffer options:(__bridge NSDictionary *)attachments];
    
    if (attachments)
        CFRelease(attachments);
    UIColor *strokeColor = [UIColor redColor];
    UIColor *fillColor = [UIColor redColor];
    
    
    NSArray *rectangles = [self detectRectangles:ciImage];
    for (CIRectangleFeature *rect in rectangles) {
        UIBezierPath *path = [self createPathFromRect:rect];
        CGRect bounds = imageView.bounds;
        
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(bounds.size.width + 2.0 * 2, bounds.size.width + 2.0 * 2),
                                               false, [UIScreen mainScreen].scale);
        
        CGContextRef context = UIGraphicsGetCurrentContext();
        
        // offset the draw to allow the line thickness to not get clipped
        CGContextTranslateCTM(context, 2, 2);
        
        [strokeColor setStroke];
        [fillColor setFill];
        
        [path fill];
        [path stroke];
        
        UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        UIImageView *rectView = [[UIImageView alloc] initWithImage:result];
        //[imageView addSubview:rectView];
    }
}

- (void)logViewHierarchy:(UIView *)view
{
    NSLog(@"%@", self);
    for (UIView *subview in view.subviews) {
        [self logViewHierarchy: subview];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)startAction:(id)sender {
}
@end
