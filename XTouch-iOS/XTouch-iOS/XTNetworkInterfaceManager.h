//
//  XTNetworkInterfaceManager.h
//  XTouch-iOS
//
//  Created by Keng Kiat Lim on 24/1/15.
//  Copyright (c) 2015 XTouch. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XTNetworkInterfaceManager : NSObject

-(void) connectWithHost:(NSString *) serverHost;
-(void) closeConnection;

@end
