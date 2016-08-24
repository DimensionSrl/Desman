//    The MIT License (MIT)
//
//    Copyright (c) 2014 m2d2
//    https://github.com/m2d2/SimpleImageCache
//
//    Permission is hereby granted, free of charge, to any person obtaining a copy
//    of this software and associated documentation files (the "Software"), to deal
//    in the Software without restriction, including without limitation the rights
//    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//    copies of the Software, and to permit persons to whom the Software is
//    furnished to do so, subject to the following conditions:
//
//    The above copyright notice and this permission notice shall be included in all
//    copies or substantial portions of the Software.
//
//    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//    SOFTWARE.

import Foundation
import UIKit

class ImageCache: NSObject, URLSessionTaskDelegate {
    static let sharedInstance = ImageCache()
	
	var session:URLSession!
	var URLCache = Foundation.URLCache(memoryCapacity: 20 * 1024 * 1024, diskCapacity: 100 * 1024 * 1024, diskPath: "ImageDownloadCache")
	var downloadQueue = Dictionary<URL, (UIImage?, NSError?)->()>()
	
	override init() {
		super.init()
		
		let config = URLSessionConfiguration.default
		config.requestCachePolicy = NSURLRequest.CachePolicy.returnCacheDataElseLoad
		config.urlCache = URLCache
		
		self.session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
	}

	func getImage(_ url:URL, completion:((UIImage?, NSError?)->())?) {
		
		let urlRequest = URLRequest(url: url, cachePolicy: NSURLRequest.CachePolicy.returnCacheDataElseLoad, timeoutInterval: 30.0)

		if let response = URLCache.cachedResponse(for: urlRequest) {
			let image = UIImage(data: response.data)
			DispatchQueue.main.async { () -> Void in
				completion?(image, nil)
				return
			}
		} else {
			let task = self.session.dataTask(with: urlRequest) { [weak self] (data, response, error) -> Void in
				if let strongSelf = self {
					if let completionHandler = strongSelf.downloadQueue[url] {
                        if let _ = error {
							DispatchQueue.main.async { 
								completionHandler(nil, nil)
								return
							}
						} else {
							if let httpResponse = response as? HTTPURLResponse {
								if httpResponse.statusCode >= 400 {
									completionHandler(nil, NSError(domain: NSURLErrorDomain, code: httpResponse.statusCode, userInfo: nil))
								} else {
                                    if let data = data, let response = response {
                                        strongSelf.URLCache.storeCachedResponse(CachedURLResponse(response:response, data:data, userInfo:nil, storagePolicy:Foundation.URLCache.StoragePolicy.allowed), for: urlRequest)
                                        let image = UIImage(data: data)
                                        DispatchQueue.main.async {
                                            completionHandler(image, nil)
                                            return
                                        }
                                    }
								}
							}
						}
					}
					strongSelf.cancelImage(url)
				}
			}
			addToQueue(url, task, completion: completion)
		}
	}
	
	func cancelImage(_ requestUrl:URL?) {
		if let url = requestUrl {
			if let index = self.downloadQueue.index(forKey: url) {
				self.downloadQueue.remove(at: index)
			}
		}
	}
	
	// MARK: - Private
	fileprivate func addToQueue(_ url:URL, _ task:URLSessionDataTask, completion:((UIImage?, NSError?)->())?) {
		self.downloadQueue[url] = completion
		if task.state != .running {
			task.resume()
		}
	}
}
