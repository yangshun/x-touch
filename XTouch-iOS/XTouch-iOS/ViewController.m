//
//  ViewController.m
//  XTouch-iOS
//
//  Created by Keng Kiat Lim on 24/1/15.
//  Copyright (c) 2015 XTouch. All rights reserved.
//

#import "ViewController.h"

@interface ViewController () {
    AVCaptureVideoPreviewLayer *previewLayer;
    IBOutlet UIView *overlayView;
    UIView *topLeft;
    UIView *topRight;
    UIView *bottomLeft;
    UIView *bottomRight;
    NSMutableArray *vs;
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
    
    vs = [NSMutableArray new];
    topLeft = [UIView new];
    topRight = [UIView new];
    bottomLeft = [UIView new];
    bottomRight = [UIView new];
    
    
    [vs addObject:topLeft];
    [vs addObject:topRight];
    [vs addObject:bottomLeft];
    [vs addObject:bottomRight];
 
    
    // Do any additional setup after loading the view, typically from a nib.
    imageView.frame = self.view.frame;
    
    CGFloat videoHeight = 352.f/288.f * self.view.frame.size.width;
    CGFloat offsetTop = (self.view.frame.size.height - videoHeight) / 2;
    overlayView.frame = CGRectMake(0, offsetTop, self.view.frame.size.width, videoHeight);
    overlayView.frame = self.view.frame;
    
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

    for (UIView *v in vs) {
        [overlayView addSubview:v];
        v.frame = CGRectMake(0, 0, 10, 10);
        v.backgroundColor = [UIColor redColor];
    }
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
    
    if (attachments) {
        CFRelease(attachments);
    }
    UIColor *strokeColor = [UIColor redColor];
    UIColor *fillColor = [UIColor redColor];
    
    
    NSArray *rectangles = [self detectRectangles:ciImage];
 
    // 352 288 1024 768
    
    CGSize s = self.view.frame.size;
    CGFloat sx = s.width/352;
    CGFloat sy = s.height/288;
    CGFloat bs = 0; CIRectangleFeature *bestr = nil;
    
    for (CIRectangleFeature *rect in rectangles) {
        CGFloat ts = (rect.topRight.x - rect.topLeft.x) * (rect.topRight.y - rect.bottomRight.y);
        if (ts > bs) {
            bs = ts;
            bestr = rect;
        }
    }
    
    topLeft.center = CGPointMake(bestr.topLeft.y * 2.9, bestr.topLeft.x * 2.67);
    topRight.center = CGPointMake(bestr.topRight.y * 2.9, bestr.topRight.x * 2.67);
    bottomRight.center = CGPointMake(bestr.bottomRight.y * 2.9, bestr.bottomRight.x * 2.67);
    bottomLeft.center = CGPointMake(bestr.bottomLeft.y * 2.9, bestr.bottomLeft.x * 2.67);
    [CATransaction flush];
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
