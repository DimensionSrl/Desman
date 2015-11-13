# Desman

An event tracking tool for mobile apps.
*Currently in early development.*

[![Cocoapods](https://img.shields.io/cocoapods/v/Desman.svg)](https://cocoapods.org/?q=desman) [![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage) [![License MIT](https://img.shields.io/cocoapods/l/desman.svg)](https://raw.githubusercontent.com/DimensionSrl/Desman/master/LICENSE) [![Platforms](https://img.shields.io/cocoapods/p/desman.svg)](http://cocoadocs.org/docsets/Desman) 

## Desman iOS

Desman implementation to collect, send, serialize and show events on a iOS app.

### Integration

We don't support CocoaPods or Carthage yet. Please choose the old way and add the *Desman* Xcode project to your own. Then add the `Desman` framework to the embedded binaries of your app's target. This method works on iOS 8 and later.

Remember to whitelist your endpoint on iOS 9 to fulfill *App Transport Security* requirements to match the required security level. Otherwise the server logging won't work and you'll get many errors on the console.

### Sample Code

In this repository you can find a sample code project with few lines of code in the `AppDelegate`'s `application:didFinishLaunchingWithOptions:` to setup `EventManager`.
You can choose to send the events to an endpoint, serialize them into `NSUserDefaults` or just keep them in memory.

### Usage

#### Integration

*Sample code is written in Swift but Objective-C should be supported too, if you find an incompability please open an issue.*

Import Desman framework into your Swift classes

```swift
import Desman
```

or if you are writing in Objective-C
```objc
#import <Desman/Desman-Swift.h>
```

*Keep in mind the you have to let the project generate the Bridging Header otherwise the integration may fail.*

#### Intialization

Initialize the `EventManager` using the `takeOff:` method.

The `serialization` parameter is useful to specify a method to locally serialize events and preserve them between application launches. Options at the moment are `None` and `UserDefaults`.

```swift
EventManager.sharedInstance.takeOff(.UserDefaults)
```

If you have a remote web service instance you can provide the url, otherwise you can simply log events locally.

```swift
EventManager.sharedInstance.takeOff(NSURL(string: "https://example.com")!, appKey: "", serialization: .UserDefaults)
```

In order to collect events you also need to call the `startLogging:` method.

```swift
EventManager.sharedInstance.startLogging()
```

To stop the collection use `stopLogging:`.

To delete every previously serialized `Event` you can use the `EventManager`'s `purgeLogs:` method.

#### Logging

Create an `Event`:

```swift
let event = Event(Application.DidFinishLaunching)
```

Log the `Event` with the `EventManager`:

```swift
EventManager.sharedInstance.log(event)
```

There is also a convenience method to speed up event logging without the need to create an `Event` first:

```swift
EventManager.sharedInstance.logType(Application.DidFinishLaunching)
```

For each `Event` you can also specify a payload as dictionary `[String : AnyObject]`. Keep in mind that this payload must be serialized, so you can only provide objects conforming to the [`NSCoding`](https://developer.apple.com/library/ios/documentation/Cocoa/Reference/Foundation/Protocols/NSCoding_Protocol/) protocol. This payload will be also sent to the server.

```swift
let event = Event(type: Application.DidFinishLaunching, payload: ["url": "example.com"])
```

### Custom Types

In order to send custom types for your events, you can create a `Type` subclass. Below a snippet to have convenience initializers.

```swift
class Rate : Type {
    static let Great = Rate(subtype: "Great")
    static let Average = Rate(subtype: "Average")
    static let Bad = Rate(subtype: "Bad")
}
```

and a new `Event` can be created providing its `Type`

```swift
let event = Event(Rate.Great)
```

You can also specify a custom image with the `Type` overriding the `image` getter method

```swift
override var image : UIImage? {
    return UIImage(named: "Unknown")
}
```

### Events View Controller

There's also a convenience `EventsTableViewController` that can be instantiated and presented modally from your application to identify and inspect the `Event`s.

```swift
let desmanStoryboard = UIStoryboard(name: "Desman", bundle: NSBundle(forClass: EventManager.self))
let desmanController = desmanStoryboard.instantiateViewControllerWithIdentifier("eventsController")
self.presentViewController(desmanController, animated: true, completion: nil)
```

## Acknowledgements

Matteo Gavagnin [@macteo](http://twitter.com/macteo) - [DIMENSION](http://www.dimension.it)
Matteo Vidotto - [DIMENSION](http://www.dimension.it)
