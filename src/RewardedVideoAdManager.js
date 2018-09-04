/**
 * RewardedVideoAdManager.js
 * react-native-fbads
 *
 * Created by Logan Hendershot on 03/10/18
 * Copyright © 2016 Callstack.io. All rights reserved.
 *
 * @flow
 */

import {NativeEventEmitter, NativeModules} from 'react-native';

const { CTKRewardedVideoAdManager } = NativeModules;

const eventEmitter = new NativeEventEmitter(CTKRewardedVideoAdManager);

const createErrorFromErrorData = (errorData) => {
  const {
    message,
    ...extraErrorInfo
  } = errorData || {};
  const error = new Error(message);
  error.framesToPop = 1;
  return Object.assign(error, extraErrorInfo);
};

const eventMap = {
  adLoaded: 'rewardedAudienceVideoAdLoaded',
  adFailedToLoad: 'rewardedAudienceVideoAdFailedToLoad',
  adClosed: 'rewardedAudienceVideoAdClosed',
  adLeftApplication: 'rewardedAudienceVideoAdLeftApplication',
  rewarded: 'rewardedAudienceVideoAdRewarded',
  videoStarted: 'rewardedAudienceVideoAdVideoStarted',
  videoCompleted: 'rewardedAudienceVideoAdVideoCompleted',
};

const _subscriptions = new Map();

const addEventListener = (event, handler) => {
  const mappedEvent = eventMap[event];
  if (mappedEvent) {
    let listener;
    if (event === 'adFailedToLoad') {
      listener = eventEmitter.addListener(mappedEvent, error => handler(createErrorFromErrorData(error)));
    } else {
      listener = eventEmitter.addListener(mappedEvent, handler);
    }
    _subscriptions.set(handler, listener);
    return {
      remove: () => removeEventListener(event, handler),
    };
  } else {
    // eslint-disable-next-line no-console
    console.warn(`Trying to subscribe to unknown event: "${event}"`);
    return {
      remove: () => {},
    };
  }
};

const removeEventListener = (type, handler) => {
  const listener = _subscriptions.get(handler);
  if (!listener) {
    return;
  }
  listener.remove();
  _subscriptions.delete(handler);
};

const removeAllListeners = () => {
  _subscriptions.forEach((listener, key, map) => {
    listener.remove();
    map.delete(key);
  });
};

export default {
  ...CTKRewardedVideoAdManager,
  addEventListener,
  removeEventListener,
  removeAllListeners,
};
