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

class ImageCache: NSObject, NSURLSessionTaskDelegate {
    static let sharedInstance = ImageCache()
	
	var session:NSURLSession!
	var URLCache = NSURLCache(memoryCapacity: 20 * 1024 * 1024, diskCapacity: 100 * 1024 * 1024, diskPath: "ImageDownloadCache")
	var downloadQueue = Dictionary<NSURL, (UIImage?, NSError?)->()>()
	
	override init() {
		super.init()
		
		let config = NSURLSessionConfiguration.defaultSessionConfiguration()
		config.requestCachePolicy = NSURLRequestCachePolicy.ReturnCacheDataElseLoad
		config.URLCache = URLCache
		
		self.session = NSURLSession(configuration: config, delegate: self, delegateQueue: nil)
	}

	func getImage(url:NSURL, completion:((UIImage?, NSError?)->())?) {
		
		let urlRequest = NSURLRequest(URL: url, cachePolicy: NSURLRequestCachePolicy.ReturnCacheDataElseLoad, timeoutInterval: 30.0)

		if let response = URLCache.cachedResponseForRequest(urlRequest) {
			let image = UIImage(data: response.data)
			dispatch_async(dispatch_get_main_queue()) { () -> Void in
				completion?(image, nil)
				return
			}
		} else {
			let task = self.session.dataTaskWithRequest(urlRequest) { [weak self] (data, response, error) -> Void in
				if let strongSelf = self {
					if let completionHandler = strongSelf.downloadQueue[url] {
                        if let _ = error {
							dispatch_async(dispatch_get_main_queue()) { 
								completionHandler(nil, nil)
								return
							}
						} else {
							if let httpResponse = response as? NSHTTPURLResponse {
								if httpResponse.statusCode >= 400 {
									completionHandler(nil, NSError(domain: NSURLErrorDomain, code: httpResponse.statusCode, userInfo: nil))
								} else {
                                    if let data = data, response = response {
                                        strongSelf.URLCache.storeCachedResponse(NSCachedURLResponse(response:response, data:data, userInfo:nil, storagePolicy:NSURLCacheStoragePolicy.Allowed), forRequest: urlRequest)
                                        let image = UIImage(data: data)
                                        dispatch_async(dispatch_get_main_queue()) {
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
	
	func cancelImage(requestUrl:NSURL?) {
		if let url = requestUrl {
			if let index = self.downloadQueue.indexForKey(url) {
				self.downloadQueue.removeAtIndex(index)
			}
		}
	}
	
	// MARK: - Private
	private func addToQueue(url:NSURL, _ task:NSURLSessionDataTask, completion:((UIImage?, NSError?)->())?) {
		self.downloadQueue[url] = completion
		if task.state != .Running {
			task.resume()
		}
	}
}
