//
//  XTNetworkInterfaceManager.h
//  XTouch-iOS
//
//  Created by Keng Kiat Lim on 24/1/15.
//  Copyright (c) 2015 XTouch. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

typedef NS_ENUM(NSUInteger, XTTouchEventType) {
    XTTouchEventDown,
    XTTouchEventUp,
    XTTouchEventMove
};

@interface XTNetworkInterfaceManager : NSObject

-(void) connectWithHost:(NSString *) serverHost;
-(void) sendTouchEvent:(XTTouchEventType)eventType withXCoord:(CGFloat) x andYCoord:(CGFloat) y;

@end
