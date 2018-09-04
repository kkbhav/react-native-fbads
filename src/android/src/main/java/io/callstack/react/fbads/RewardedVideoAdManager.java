package io.callstack.react.fbads;

import com.facebook.ads.Ad;
import com.facebook.ads.AdError;
import com.facebook.ads.RewardedVideoAd;
import com.facebook.ads.RewardedVideoAdListener;
import com.facebook.react.bridge.LifecycleEventListener;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.modules.core.DeviceEventManagerModule;

import android.support.annotation.Nullable;
import android.util.Log;

public class RewardedVideoAdManager extends ReactContextBaseJavaModule implements LifecycleEventListener, RewardedVideoAdListener {

    private ReactContext reactContext;
    private Promise mLoadedPromise = null;
    private Promise mShowPromise = null;
    private Ad ad = null;

    private String TAG = "RewardedVideo";

    public static final String EVENT_AD_LOADED = "rewardedAudienceVideoAdLoaded";
    public static final String EVENT_AD_FAILED_TO_LOAD = "rewardedAudienceVideoAdFailedToLoad";
    public static final String EVENT_AD_OPENED = "rewardedAudienceVideoAdOpened";
    public static final String EVENT_AD_CLOSED = "rewardedAudienceVideoAdClosed";
    public static final String EVENT_AD_LEFT_APPLICATION = "rewardedAudienceVideoAdLeftApplication";
    public static final String EVENT_REWARDED = "rewardedAudienceVideoAdRewarded";
    public static final String EVENT_VIDEO_STARTED = "rewardedAudienceVideoAdVideoStarted";
    public static final String EVENT_VIDEO_COMPLETED = "rewardedAudienceVideoAdVideoCompleted";

    private RewardedVideoAd mRewardedVideoAd;


    public RewardedVideoAdManager(ReactApplicationContext reactContext) {
        super(reactContext);
        this.reactContext = reactContext;
        reactContext.addLifecycleEventListener(this);
    }

    private void sendEvent(String eventName, @Nullable WritableMap params) {
        getReactApplicationContext().getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class).emit(eventName, params);
    }

    @ReactMethod
    public void setPlacementId(String placementId) {
        if (mRewardedVideoAd != null) {
            mRewardedVideoAd.destroy();
        }
        mRewardedVideoAd = new RewardedVideoAd(reactContext.getApplicationContext(), placementId);
        mRewardedVideoAd.setAdListener(this);
    }

    @ReactMethod
    public void showAd(Promise p) {
        if (mShowPromise != null) {
            p.reject("E_FAILED_TO_SHOW", "Only one `showAd` can be called at once");
            return;
        }
        if (mRewardedVideoAd != null && mRewardedVideoAd.isAdLoaded()) {
            mRewardedVideoAd.show();
            mShowPromise = p;
        }
    }

    @ReactMethod
    public void loadAd(String placementId, Promise p) {
        if (mLoadedPromise != null) {
            p.reject("E_FAILED_TO_SHOW", "Only one `loadAd` can be called at once");
            return;
        } else if (mRewardedVideoAd == null) {
            p.reject("E_FAILED_TO_INIT", "You need to set placement Id first");
        } else if (mRewardedVideoAd.isAdLoaded()) {
            p.reject("E_AD_ALREADY_LOADED", "Ad is already loaded.");
        }

        mLoadedPromise = p;

        mRewardedVideoAd.loadAd();
    }

    @Override
    public String getName() {
        return "CTKRewardedVideoAdManager";
    }

    private void cleanUp() {
        mLoadedPromise = null;
        mShowPromise = null;
        ad = null;
    }

    @Override
    public void onHostResume() {

    }

    @Override
    public void onHostPause() {

    }

    @Override
    public void onHostDestroy() {
        cleanUp();
        if (mRewardedVideoAd != null) {
            mRewardedVideoAd.destroy();
            mRewardedVideoAd = null;
        }
    }

    @Override
    public void onRewardedVideoCompleted() {
        // Rewarded Video View Complete - the video has been played to the end.
        // You can use this event to initialize your reward
        Log.d(TAG, "Rewarded video completed!");
        sendEvent(EVENT_VIDEO_COMPLETED, null);
        sendEvent(EVENT_REWARDED, null);
        cleanUp();
    }

    @Override
    public void onError(Ad ad, AdError error) {
        // Rewarded video ad failed to load
        Log.e(TAG, "Rewarded video ad failed to load: " + error.getErrorMessage());
        mLoadedPromise.reject("E_FAILED_TO_SHOW",
                "Rewarded video ad failed to load: " + error.getErrorMessage());
        sendEvent(EVENT_AD_FAILED_TO_LOAD, null);
        cleanUp();
    }

    @Override
    public void onAdLoaded(Ad ad) {
        // Rewarded video ad is loaded and ready to be displayed
        Log.d(TAG, "Rewarded video ad is loaded and ready to be displayed!");
        this.ad = ad;
        mLoadedPromise.resolve(true);
        sendEvent(EVENT_AD_LOADED, null);
    }

    @Override
    public void onAdClicked(Ad ad) {
        // Rewarded video ad clicked
        Log.d(TAG, "Rewarded video ad clicked!");
        sendEvent(EVENT_AD_LEFT_APPLICATION, null);
    }

    @Override
    public void onLoggingImpression(Ad ad) {
        // Rewarded Video ad impression - the event will fire when the
        // video starts playing
        Log.d(TAG, "Rewarded video ad impression logged!");
        mShowPromise.resolve(true);
        sendEvent(EVENT_VIDEO_STARTED, null);
    }

    @Override
    public void onRewardedVideoClosed() {
        // The Rewarded Video ad was closed - this can occur during the video
        // by closing the app, or closing the end card.
        Log.d(TAG, "Rewarded video ad closed!");
        sendEvent(EVENT_AD_CLOSED, null);
    }
}
