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

@interface XTNetworkInterfaceManager ()

@property (nonatomic) NSUInteger userId;
@property (nonatomic, strong) SIOSocket *sioSocket;

@end

@implementation XTNetworkInterfaceManager

-(void)connectWithHost:(NSString *)serverHost {
    [SIOSocket socketWithHost:serverHost response:^(SIOSocket *socket) {
        self.sioSocket = socket;
        [self.sioSocket on:USER_CONNECTED_EVENT callback:^(NSArray *args) {
            self.userId = (NSUInteger) args[0][@"newUserId"];
        }];
        [self.sioSocket emit:USER_CONNECT_EVENT];
    }];
}

-(void) closeConnection {
    
}

@end
