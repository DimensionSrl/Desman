//
//  NotificationCenterListener.swift
//  Desman iOS Sample
//
//  Created by Matteo Gavagnin on 19/10/15.
//  Copyright © 2015 DIMENSION S.r.l. All rights reserved.
//

import Foundation
import Photos

let kNotificationCenterEvent = "notificationCenterEvent"

internal class NotificationCenterManager : NSObject {

    /**
    A shared instance of `NotificationCenterManager`.
    */
    static internal let sharedInstance = NotificationCenterManager()
    
    internal func listenToScreenshots() {
        startListeningForScreenshots()
    }
    
    internal func stopListeningToScreenshots() {
        stopListening(UIApplicationUserDidTakeScreenshotNotification)
    }
    
    internal func listenToAppLifecycleActivity() {
        startListening(UIApplicationDidBecomeActiveNotification, type: Application.DidBecomeActive)
        startListening(UIApplicationDidEnterBackgroundNotification, type: Application.DidEnterBackground)
        // startListening(UIApplicationDidFinishLaunchingNotification, type: Application.DidFinishLaunching)
        startListening(UIApplicationWillEnterForegroundNotification, type: Application.WillEnterForeground)
        startListening(UIApplicationWillResignActiveNotification, type: Application.WillResignActive)
        startListening(UIApplicationWillTerminateNotification, type: Application.WillTerminate)
    }
    
    internal func stopListeningToAppLifecycleActivity() {
        stopListening(UIApplicationDidBecomeActiveNotification)
        stopListening(UIApplicationDidEnterBackgroundNotification)
        // stopListening(UIApplicationDidFinishLaunchingNotification)
        stopListening(UIApplicationWillEnterForegroundNotification)
        stopListening(UIApplicationWillResignActiveNotification)
        stopListening(UIApplicationWillTerminateNotification)
    }
    
    internal func startListening(name: String, type: Type) {
        stopListening(name)
        NSNotificationCenter.defaultCenter().addObserverForName(name, object: nil, queue: nil) { (notification) -> Void in
            var payload = [String: Coding]()
            if let object = notification.object {
                if let object = object as? Coding {
                    payload["object"] = object
                } else {
                    payload["object"] = object.description
                }
            }
            if let userInfo = notification.userInfo {
                payload["userInfo"] = userInfo
            }
            if type.subtype == "" {
                type.subtype = notification.name
            }
            let event = Event(type: type, payload: payload)
            EventManager.sharedInstance.log(event)
        }
    }
    
    func startListeningForScreenshots() {
        stopListening(UIApplicationUserDidTakeScreenshotNotification)
        NSNotificationCenter.defaultCenter().addObserverForName(UIApplicationUserDidTakeScreenshotNotification, object: nil, queue: nil) { (notification) -> Void in
            if #available(iOS 8.0, *) {
                let imgManager = PHImageManager.defaultManager()
                let fetchOptions = PHFetchOptions()
                fetchOptions.sortDescriptors = [NSSortDescriptor(key:"creationDate", ascending: true)]
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(0.50 * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) {
                    if let fetchResult: PHFetchResult = PHAsset.fetchAssetsWithMediaType(PHAssetMediaType.Image, options: fetchOptions) {
                        if fetchResult.count > 0 {
                            let assetResult = fetchResult.objectAtIndex(fetchResult.count - 1) as! PHAsset
                            imgManager.requestImageDataForAsset(assetResult, options: nil, resultHandler: { (data, string, orientation, userInfo) -> Void in
                                if let data = data {
                                    let event = Event(type: Controller.Screenshot, payload: ["controller": "View Controller"], attachment: data)
                                    Des.log(event)
                                }
                            })
                        }
                    }
                }
            } else {
                // Fallback on earlier versions
            }
            
        }
    }
    
    internal func stopListening(name: String) {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: name, object: nil)
    }
}