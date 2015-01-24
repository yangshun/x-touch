//
//  ViewController.m
//  XTouch-iOS
//
//  Created by Keng Kiat Lim on 24/1/15.
//  Copyright (c) 2015 XTouch. All rights reserved.
//

#import "ViewController.h"
#import "XTNetworkInterfaceManager.h"

#define SERVER_HOST @"http://172.20.10.2:3000"
#define RED_COLOR [UIColor redColor]

@interface ViewController () {
    AVCaptureVideoPreviewLayer *previewLayer;
    UIView *overlayView;
    UIView *topLeft;
    UIView *topRight;
    UIView *bottomLeft;
    UIView *bottomRight;
    NSMutableArray *vs;
}

@property (nonatomic) BOOL inRect;
@property (nonatomic, strong) XTNetworkInterfaceManager *networkManager;

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
    
    self.networkManager = [[XTNetworkInterfaceManager alloc] init];
    [self.networkManager connectWithHost:SERVER_HOST];
    
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
    overlayView = [[UIView alloc] initWithFrame:CGRectMake(0, offsetTop, self.view.frame.size.width, videoHeight)];
    [self.view addSubview:overlayView];
    
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
    
    NSArray *rectangles = [self detectRectangles:ciImage];
    
    CGSize s = overlayView.frame.size;
    CGFloat sy = s.height/352;
    CGFloat sx = s.width/288;
    CGFloat bs = 0; CIRectangleFeature *bestr = nil;
    
    for (CIRectangleFeature *rect in rectangles) {
        CGFloat ts = (rect.topRight.x - rect.topLeft.x) * (rect.topRight.y - rect.bottomRight.y);
        if (ts > bs) {
            bs = ts;
            bestr = rect;
        }
    }
    
    if (bs > 0) {
        topLeft.center = CGPointMake(bestr.topLeft.y * sy, bestr.topLeft.x * sx);
        topRight.center = CGPointMake(bestr.topRight.y * sy, bestr.topRight.x * sx);
        bottomRight.center = CGPointMake(bestr.bottomRight.y * sy, bestr.bottomRight.x * sx);
        bottomLeft.center = CGPointMake(bestr.bottomLeft.y * sy, bestr.bottomLeft.x * sx);
        [CATransaction flush];
    }
}

- (IBAction)handleGesture:(UIPanGestureRecognizer *)sender {
    CGPoint point = [sender locationInView:self.view];
    CGFloat translatedX = (point.x - topLeft.center.y) / (topRight.center.y - topLeft.center.y);
    CGFloat translatedY = (point.y - bottomLeft.center.x) / (topLeft.center.x - bottomLeft.center.x);
    
    if (translatedX < 0.0
        || translatedX > 1.0
        || translatedY < 0.0
        || translatedY > 1.0
        || sender.state == UIGestureRecognizerStateEnded) {
        if (self.inRect == YES) {
            [self.networkManager sendTouchEvent:XTTouchEventUp withXCoord:translatedX andYCoord:translatedY];
        }
        
        self.inRect = NO;
        return;
    }
    
    if (self.inRect == NO) {
        [self.networkManager sendTouchEvent:XTTouchEventDown withXCoord:translatedX andYCoord:translatedY];
        self.inRect = YES;
    } else {
        [self.networkManager sendTouchEvent:XTTouchEventMove withXCoord:translatedX andYCoord:translatedY];
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
}

@end
