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
        stopListening(.UIApplicationUserDidTakeScreenshot)
    }
    
    internal func listenToAppLifecycleActivity() {
        startListening(.UIApplicationDidBecomeActive, type: AppCycle.DidBecomeActive)
        startListening(.UIApplicationDidEnterBackground, type: AppCycle.DidEnterBackground)
        // startListening(UIApplicationDidFinishLaunchingNotification, type: Application.DidFinishLaunching)
        startListening(.UIApplicationWillEnterForeground, type: AppCycle.WillEnterForeground)
        startListening(.UIApplicationWillResignActive, type: AppCycle.WillResignActive)
        startListening(.UIApplicationWillTerminate, type: AppCycle.WillTerminate)
    }
    
    internal func stopListeningToAppLifecycleActivity() {
        stopListening(NSNotification.Name.UIApplicationDidBecomeActive)
        stopListening(NSNotification.Name.UIApplicationDidEnterBackground)
        // stopListening(UIApplicationDidFinishLaunchingNotification)
        stopListening(NSNotification.Name.UIApplicationWillEnterForeground)
        stopListening(NSNotification.Name.UIApplicationWillResignActive)
        stopListening(NSNotification.Name.UIApplicationWillTerminate)
    }
    
    internal func startListening(_ name: NSNotification.Name, type: DType) {
        stopListening(name)
        NotificationCenter.default.addObserver(forName: name, object: nil, queue: nil) { (notification) -> Void in
            var payload = [String: Any]()
            if let object = notification.object {
                if let object = object as? NSCoding {
                    payload["object"] = object
                }
            }
            if let userInfo = (notification as NSNotification).userInfo {
                payload["userInfo"] = userInfo
            }
            if type.subtype == "" {
                type.subtype = String(describing: notification.name)
            }
            let event = Event(type: type, payload: payload)
            EventManager.shared.log(event)
        }
    }
    
    func startListeningForScreenshots() {
        stopListening(.UIApplicationUserDidTakeScreenshot)
        NotificationCenter.default.addObserver(forName: NSNotification.Name.UIApplicationUserDidTakeScreenshot, object: nil, queue: nil) { (notification) -> Void in
            if #available(iOS 8.0, *) {
                let imgManager = PHImageManager.default()
                let fetchOptions = PHFetchOptions()
                fetchOptions.sortDescriptors = [NSSortDescriptor(key:"creationDate", ascending: true)]
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(0.50 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)) {
                    let fetchResult: PHFetchResult = PHAsset.fetchAssets(with: PHAssetMediaType.image, options: fetchOptions)
                    if fetchResult.count > 0 {
                        let assetResult = fetchResult.object(at: fetchResult.count - 1) 
                        imgManager.requestImageData(for: assetResult, options: nil, resultHandler: { (data, string, orientation, userInfo) -> Void in
                            if let data = data {
                                let event = Event(type: Controller.Screenshot, payload: ["controller": "View Controller" as NSCoding], attachment: data as Data)
                                Des.log(event)
                            }
                        })
                    }
                }
            } else {
                // Fallback on earlier versions
            }
            
        }
    }
    
    internal func stopListening(_ name: NSNotification.Name) {
        NotificationCenter.default.removeObserver(self, name: name, object: nil)
    }
}
