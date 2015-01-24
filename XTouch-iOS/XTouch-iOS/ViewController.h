//
//  ViewController.h
//  XTouch-iOS
//
//  Created by Keng Kiat Lim on 24/1/15.
//  Copyright (c) 2015 XTouch. All rights reserved.
//


#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface ViewController : UIViewController <AVCaptureVideoDataOutputSampleBufferDelegate>
{
    __weak IBOutlet UIImageView *imageView;
    dispatch_queue_t videoDataOutputQueue;
}
- (NSArray *)detectRectangles:(CIImage *)image;
- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection;
- (IBAction)handleGesture:(UIPanGestureRecognizer *)sender;
@end

