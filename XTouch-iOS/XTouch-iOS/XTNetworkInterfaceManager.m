//
//  XTNetworkInterfaceManager.m
//  XTouch-iOS
//
//  Created by Keng Kiat Lim on 24/1/15.
//  Copyright (c) 2015 XTouch. All rights reserved.
//

#import "XTNetworkInterfaceManager.h"
#import <SIOSocket/SIOSocket.h>

#define USER_CONNECT_EVENT @"user join"
#define USER_CONNECTED_EVENT @"user joined"
#define USER_TOUCH_DOWN_EVENT @"drag touchdown"
#define USER_TOUCH_UP_EVENT @"drag touchup"
#define USER_TOUCH_MOVE_EVENT @"drag touchmove"
#define USER_PHOTO_EVENT @"show image"

@interface XTNetworkInterfaceManager ()

@property (nonatomic, strong) NSString *userId;
@property (nonatomic, strong) SIOSocket *sioSocket;
@property (nonatomic, strong) NSArray *eventMessages;

@end

@implementation XTNetworkInterfaceManager

-(id)init {
    self = [super init];
    if (self) {
        self.eventMessages = @[USER_TOUCH_DOWN_EVENT, USER_TOUCH_UP_EVENT, USER_TOUCH_MOVE_EVENT];
    }
    return self;
}

-(void)connectWithHost:(NSString *)serverHost {
    [SIOSocket socketWithHost:serverHost response:^(SIOSocket *socket) {
        self.sioSocket = socket;
        [self.sioSocket on:USER_CONNECTED_EVENT callback:^(NSArray *args) {
            self.userId = [NSString stringWithFormat:@"%li",  (NSUInteger)args[0][@"newUserId"]];
        }];
        [self.sioSocket emit:USER_CONNECT_EVENT];
    }];
}

-(void)sendTouchEvent:(XTTouchEventType)eventType withXCoord:(CGFloat)x andYCoord:(CGFloat)y {
    NSString *eventString = self.eventMessages[eventType];
    NSString *xString = [NSString stringWithFormat:@"%f", x];
    NSString *yString = [NSString stringWithFormat:@"%f", y];
    
    NSDictionary *parameters = @{@"userId": self.userId, @"x": xString, @"y": yString};
    [self.sioSocket emit:eventString args:@[parameters]];
}

-(void)triggerPhoto {
    [self.sioSocket emit:USER_PHOTO_EVENT];
    NSLog(@"Photo triggered");
}

@end
