![](https://raw.github.com/DimensionSrl/Desman/Assets/Icon-Bordered.svg)

# Desman

An event tracking tool for mobile apps.

[![CocoaPods](https://img.shields.io/cocoapods/v/Desman.svg)](https://cocoapods.org/?q=desman) [![License MIT](https://img.shields.io/cocoapods/l/desman.svg)](https://raw.githubusercontent.com/DimensionSrl/Desman/master/LICENSE) [![Platforms](https://img.shields.io/cocoapods/p/desman.svg)](http://cocoadocs.org/docsets/Desman) [![Version](https://img.shields.io/cocoapods/v/desman.svg)](http://cocoadocs.org/docsets/Desman) [![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

*Currently in early development.*

## Features

- [x] Remote logging in realtime.
- [x] Events serialization on `NSUserDefaults` and `CoreData`.
- [x] Custom events and types.
- [x] Event templates with types.
- [x] Automatic screenshot detection and upload.
- [x] App icon upload.
- [x] Customizable payload can be set on each event.
- [x] Event attachments as `NSData`.
- [x] On device events list interface.
- [x] Optional convenience features at your own risk (swizzling).
- [x] Curated images associated to events.
- [ ] `print` and `NSLog` replacement.
- [ ] Opportunistic events upload.
- [ ] Authentication.
- [ ] Well documented.
- [ ] Tested.
- [ ] User activated remote logging visiting a web page.
- [ ] SSL encryption.
- [ ] Crash log detection and upload.
- [ ] Event filter and search.

![Event](https://raw.github.com/DimensionSrl/Desman/Assets/screenshots/Events.png) ![Events](https://raw.github.com/DimensionSrl/Desman/Assets/screenshots/Event.png) ![Event gif](https://raw.github.com/DimensionSrl/Desman/Assets/gifs/Event.gif)

## Requirements

- iOS 8.0+
- Xcode 7.0+

## Installation

Desman is extremely lightweight. Even including the resource files and interface, your app will increase of just 1.4 MB or only 1.2 MB if you also enable [bitcode](https://developer.apple.com/library/ios/documentation/IDEs/Conceptual/AppDistributionGuide/AppThinning/AppThinning.html).

### CocoaPods

[CocoaPods](http://cocoapods.org) is a dependency manager for Cocoa projects. You can install it with the following command:

```bash
$ gem install cocoapods
```

> CocoaPods 0.39.0+ is required to build Desman.

To integrate Desman into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '8.0'
use_frameworks!

pod 'Desman'
```

Then, run the following command:

```bash
$ pod install
```

#### Subspecs

Desman is packaged with many subspecs to limit the number of classes and assets that needs to be included in your shipping app.

The **Core** default subspec is included by default and contains only the basic classes (and no assets) to log, serialize and upload events. It lets you present to the user a list of `Event`s logged on the current device.
The **Debatable** subspec includes classes that can change the behavior of your application like method swizzling. Please take a look at the source code and decide if it fits your needs or not.
The **Remote** subspec includes the ability to select another application or another user and receive the previously logged `Event`s.

### Carthage

[Carthage](https://github.com/Carthage/Carthage) is a decentralized dependency manager that builds your dependencies and provides you with binary frameworks.

You can install [Carthage](https://github.com/Carthage/Carthage) with [Homebrew](http://brew.sh/) using the following command:

```bash
$ brew update
$ brew install carthage
```

To integrate Desman into your Xcode project using [Carthage](https://github.com/Carthage/Carthage), specify it in your `Cartfile`:

```ogdl
github "DimensionSrl/Desman"
```

Run `carthage update --platform iOS` to build the framework and drag the built `Desman.framework` into your Xcode project to include only the **Core** features.

> If you choose this method you won't have the flexibility offered by CocoaPods to integrate only the part of code of your interest: the debatable features will be included too.

To include also the **Remote** features, add also the `DesmanRemote.framework` to your project. You also need to add the `SwiftWebSocket.framework` as it's a required dependency.

### Manually

Add the *Desman* Xcode project to your own. Then add the `Desman Core iOS` and `Desman Remote iOS` frameworks as desired to the embedded binaries of your app's target.

## Sample Code

In this repository you can find a sample code project with few lines of code in the `AppDelegate`'s `application:didFinishLaunchingWithOptions:` to setup `EventManager`.
You can choose to send the events to an endpoint, serialize them into `NSUserDefaults` or just keep them in memory.

## Usage

### Integration

*Sample code is written in Swift but Objective-C should be supported too, if you find an incompatibility please open an issue.*

Import *Desman* and optionally *DesmanRemote* modules into your Swift classes

```swift
import Desman
```

or if you are writing in Objective-C
```objc
#import <Desman/Desman-Swift.h>
```

If you integrate Desman with CocoaPods, you don't have to include *DesmanRemote* (only *Desman* is enough) as a single module will be produced, with everything included.

> Keep in mind the you have to let the project generate the Bridging Header otherwise the integration may fail.

#### Intialization

Initialize the `EventManager` using the `takeOff:` method.

The `serialization` parameter is useful to specify a method to locally serialize events and preserve them between application launches. Options at the moment are `None` and `UserDefaults`.

```swift
EventManager.sharedInstance.takeOff(.UserDefaults)
```

If you have a remote web service instance you can provide the url, otherwise you can simply log events locally.

```swift
EventManager.sharedInstance.takeOff(NSURL(string: "https://example.com")!, appKey: "1234567890abcdef", serialization: .UserDefaults)
```

In order to collect events you also need to call the `startLogging:` method.

```swift
EventManager.sharedInstance.startLogging()
```

To stop the collection use `stopLogging:`.

To delete every previously serialized `Event` you can use the `EventManager`'s `purgeLogs:` method.

### Logging

Create an `Event`:

```swift
let event = Event(Application.DidFinishLaunching)
```

Log the `Event` with the `EventManager`:

```swift
EventManager.sharedInstance.log(event)
```

or using the `EventManager.sharedInstance` shorter `Des` alias

```swift
Des.log(event)
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

### Interface

There's also some classes to represent the events logged on the local device, mostly useful during development, that can be summoned and presented modally from your application to identify and inspect the `Event`s.

```swift
let desmanStoryboard = UIStoryboard(name: "Desman", bundle: NSBundle(forClass: EventsController.self))
let desmanController = desmanStoryboard.instantiateViewControllerWithIdentifier("eventsController")
self.presentViewController(desmanController, animated: true, completion: nil)
```

### Remote Logging

Desman includes the ability to observe the events occurring in realtime on a remote device. To summon the remote logging interface to be integrated in your application, you need to include the `Remote` CocoaPods subspecs, use Carthage, or use the manual process and:

```swift
let desmanBundle = NSBundle(forClass: RemoteController.self)
let desmanStoryboard = UIStoryboard(name: "Remote", bundle: desmanBundle)
let desmanController = desmanStoryboard.instantiateViewControllerWithIdentifier("remoteController")
self.presentViewController(desmanController, animated: true, completion: nil)
```

### Dependancies

Desman has no dependancies at the moment, except if you choose the `Remote` CocoaPods subspec (or the Carthage integration), that requires the [SwiftWebSocket](https://github.com/tidwall/SwiftWebSocket) to open a websocket channel to receive events from the server.

We've also included directly as class a modified copy of [SimpleImageCache](https://github.com/m2d2/SimpleImageCache) originally written by [m2d2](https://github.com/m2d2) and released under the MIT License.

The `CoreDataSerializerManager.swift` class is heavily inspired by [this sample code](https://github.com/mdelamata/CoreDataManager-Swift) written by Manuel de la Mata. Unfortunately no license is specified.

## Development

In order to build the Desman Remote iOS framework with Xcode, you have to install Carthage as it depends on it.

```bash
carthage build --no-skip-current --platform iOS
```

To test the Desman.podspec correctness use

```bash
pod spec lint Desman.podspec
```

You should also include checked out versions of the dependancies for the sample project, so always perform a

```bash
cd Sample
pod update
```

and check if it builds.

## Acknowledgements

Matteo Gavagnin [@macteo](http://twitter.com/macteo) – [DIMENSION](http://www.dimension.it) – Design, implementation and documentation.
Daniele Dalledonne [@ddalledo](http://twitter.com/ddalledo) – [DIMENSION](http://www.dimension.it) – Initial idea.
Matteo Vidotto – [DIMENSION](http://www.dimension.it) – First integrations and manual testing.

## License

Desman is released under the MIT license. See LICENSE for details.
