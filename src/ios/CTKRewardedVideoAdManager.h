//
//  CTKRewardedVideoAdManager.h
//  rn-fbads
//
//  Created by Logan Hendershot on 4/5/18.
//  Copyright © 2018 callstack. All rights reserved.
//

#if __has_include(<React/RCTBridgeModule.h>)
#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>
#else
#import "RCTBridgeModule.h"
#import "RCTEventEmitter.h"
#endif

@interface CTKRewardedVideoAdManager : RCTEventEmitter <RCTBridgeModule>

@end
