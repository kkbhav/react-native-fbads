//
//  CTKRewardedVideoAdManager.m
//  rn-fbads
//
//  Created by Logan Hendershot on 4/4/18.
//  Copyright © 2018 callstack. All rights reserved.
//

#import "CTKRewardedVideoAdManager.h"
@import FBAudienceNetwork;
#if __has_include(<React/RCTUtils.h>)
  #import <React/RCTUtils.h>
#else
  #import "RCTUtils.h"
#endif

@interface CTKRewardedVideoAdManager () <FBRewardedVideoAdDelegate>

@property (nonatomic, strong) RCTPromiseResolveBlock resolveLoad;
@property (nonatomic, strong) RCTPromiseRejectBlock rejectLoad;
@property (nonatomic, strong) RCTPromiseResolveBlock resolveShow;
@property (nonatomic, strong) RCTPromiseRejectBlock rejectShow;
@property (nonatomic, strong) FBRewardedVideoAd *rewardedVideoAd;
@property (nonatomic, strong) RCTResponseSenderBlock callback;

@property (nonatomic) bool didLoad;

@end

static NSString *const kEventAdLoaded = @"rewardedAudienceVideoAdLoaded";
static NSString *const kEventAdFailedToLoad = @"rewardedAudienceVideoAdFailedToLoad";
static NSString *const kEventAdOpened = @"rewardedAudienceVideoAdOpened";
static NSString *const kEventAdClosed = @"rewardedAudienceVideoAdClosed";
static NSString *const kEventAdLeftApplication = @"rewardedAudienceVideoAdLeftApplication";
static NSString *const kEventRewarded = @"rewardedAudienceVideoAdRewarded";
static NSString *const kEventVideoStarted = @"rewardedAudienceVideoAdVideoStarted";
static NSString *const kEventVideoCompleted = @"rewardedAudienceVideoAdVideoCompleted";

@implementation CTKRewardedVideoAdManager
{
  BOOL hasListeners;
  NSString *_adUnitID;
};

- (dispatch_queue_t)methodQueue
{
  return dispatch_get_main_queue();
}

+ (BOOL)requiresMainQueueSetup
{
  return NO;
}


RCT_EXPORT_MODULE()

- (NSArray<NSString *> *)supportedEvents
{
      return @[
        kEventRewarded,
        kEventAdLoaded,
        kEventAdFailedToLoad,
        kEventAdOpened,
        kEventVideoStarted,
        kEventAdClosed,
        kEventAdLeftApplication,
        kEventVideoCompleted ];
}

RCT_EXPORT_METHOD(setPlacementId:(NSString *)adUnitID)
{
    _adUnitID = adUnitID;
    _rewardedVideoAd = [[FBRewardedVideoAd alloc] initWithPlacementID:adUnitID];
    _rewardedVideoAd.delegate = self;
}

RCT_EXPORT_METHOD(
                  loadAd:(NSString *)placementId
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject
                  ) {
    NSLog(@"Loading Rewarded Video");
    _resolveLoad = resolve;
    _rejectLoad = reject;

    [_rewardedVideoAd loadAd];
}

RCT_EXPORT_METHOD(showAd: (RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
    if(_didLoad != true) {
        return reject(@"E_FAILED_TO_Show", @"Rewarded video ad not loaded, unable to show.", nil);
    }
    NSLog(@"Showing Ad");
    // set callback to be called by rewardedVideoAdComplete below
    _resolveShow = resolve;

    // dispatch async to get main UI thread to show video
    dispatch_async(dispatch_get_main_queue(), ^{
        [_rewardedVideoAd showAdFromRootViewController:RCTPresentedViewController()];
    });
}

- (void)startObserving
{
  hasListeners = YES;
}

    - (void)stopObserving
{
  hasListeners = NO;
}

- (void)rewardedVideoAd:(FBRewardedVideoAd *)rewardedVideoAd didFailWithError:(NSError *)error
{
    NSLog(@"Rewarded video ad failed to load - Error: %@", error);

    _didLoad = false;
    _rejectLoad(@"E_FAILED_TO_LOAD", @"Rewarded video ad failed to load", nil);
    if (hasListeners) {
        NSDictionary *jsError = RCTJSErrorFromCodeMessageAndNSError(@"E_AD_FAILED_TO_LOAD", error.localizedDescription, error);
        [self sendEventWithName:kEventAdFailedToLoad body:jsError];
    }
}

- (void)rewardedVideoAdDidLoad:(FBRewardedVideoAd *)rewardedVideoAd
{
    NSLog(@"Video ad is loaded and ready to be displayed");
    _didLoad = true;
    _resolveLoad(@"Video ad is loaded and ready to be displayed");
    if (hasListeners) {
        [self sendEventWithName:kEventAdLoaded body:nil];
    }
}
- (void)rewardedVideoAdDidClick:(FBRewardedVideoAd *)rewardedVideoAd
{
    NSLog(@"Video ad clicked");
    if (hasListeners) {
        [self sendEventWithName:kEventAdLeftApplication body:nil];
    }
}
- (void)rewardedVideoAdComplete:(FBRewardedVideoAd *)rewardedVideoAd
{
    NSLog(@"Rewarded Video ad video complete - init reward");

    _resolveShow(@"Rewarded video ad completed successfully.");
    if (hasListeners) {
        [self sendEventWithName:kEventVideoCompleted body:nil];
        [self sendEventWithName:kEventRewarded body:nil];
    }

    [self cleanUpPromise];
}
- (void)rewardedVideoAdDidClose:(FBRewardedVideoAd *)rewardedVideoAd
{
    NSLog(@"Rewarded Video ad closed - this can be triggered by closing the application, or closing the video end card");
    if (hasListeners) {
        [self sendEventWithName:kEventAdClosed body:nil];
    }
}
- (void)rewardedVideoAdWillClose:(FBRewardedVideoAd *)rewardedVideoAd
{
    NSLog(@"The user clicked on the close button, the ad is just about to close");

}

- (void)rewardedVideoAdWillLogImpression:(FBRewardedVideoAd *)rewardedVideoAd
{
    NSLog(@"Rewarded Video impression is being captured");
    if (hasListeners) {
        [self sendEventWithName:kEventAdOpened body:nil];
        [self sendEventWithName:kEventVideoStarted body:nil];
    }
}

- (void)cleanUpPromise {
    _rejectLoad = nil;
    _resolveLoad = nil;
    _rejectShow = nil;
    _resolveShow = nil;
    _didLoad = false;
}
@end

