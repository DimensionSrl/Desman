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

public class NotificationCenterManager : NSObject {

    /**
    A shared instance of `NotificationCenterManager`.
    */
    static public let sharedInstance = NotificationCenterManager()
    
    public func listenToScreenshots() {
        startListeningForScreenshots()
    }
    
    public func stopListeningToScreenshots() {
        stopListening(UIApplicationUserDidTakeScreenshotNotification)
    }
    
    public func listenToAppLifecycleActivity() {
        startListening(UIApplicationDidBecomeActiveNotification, type: Application.DidBecomeActive)
        startListening(UIApplicationDidEnterBackgroundNotification, type: Application.DidEnterBackground)
        // startListening(UIApplicationDidFinishLaunchingNotification, type: Application.DidFinishLaunching)
        startListening(UIApplicationWillEnterForegroundNotification, type: Application.WillEnterForeground)
        startListening(UIApplicationWillResignActiveNotification, type: Application.WillResignActive)
        startListening(UIApplicationWillTerminateNotification, type: Application.WillTerminate)
    }
    
    public func stopListeningToAppLifecycleActivity() {
        stopListening(UIApplicationDidBecomeActiveNotification)
        stopListening(UIApplicationDidEnterBackgroundNotification)
        // stopListening(UIApplicationDidFinishLaunchingNotification)
        stopListening(UIApplicationWillEnterForegroundNotification)
        stopListening(UIApplicationWillResignActiveNotification)
        stopListening(UIApplicationWillTerminateNotification)
    }
    
    public func startListening(name: String, type: Type) {
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
                                D.log(event)
                            }
                        })
                    }
                }
            }
        }
    }
    
    public func stopListening(name: String) {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: name, object: nil)
    }
}