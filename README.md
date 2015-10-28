# Desman

An event tracking tool for mobile apps.
*Currently in early development.*

## Desman iOS

Desman implementation to collect, send, serialize and show events on a iOS app.

### Integration

We don't support CocoaPods or Carthage yet. Please choose the old way and add the *Desman* Xcode project to your own. Then add the `Desman` framework to the embedded binaries of your app's target. This method works on iOS 8 and later.

Remember to whitelist your endpoint on iOS 9 to fulfill *App Transport Security* requirements to match the required security level. Otherwise the server logging won't work and you'll get many errors on the console.

### Sample Code

In this repository you can find a sample code project with few lines of code in the `AppDelegate`'s `application:didFinishLaunchingWithOptions` to setup `EventManager`.
You can choose to send the events to an endpoint, serialize them into `NSUserDefaults` or just keep them in memory.

### Usage

*Sample code is written in Swift but Objective-C should be supported too, if you find an incompability please open an issue.*

Import Desman framework.

```swift
import Desman
```

Create an `Event`:

```swift
let event = Event(Application.DidFinishLaunching)
```

Log an `Event`:

```swift
EventManager.sharedInstance.log(event)
```

There is also a convenience method to speed up event logging without the need to create an `Event` first

```swift
EventManager.sharedInstance.log(Application.DidFinishLaunching)
```

For each `Event` you can also specify a payload that will be serialized as dictionary `[String : AnyObject]`. This payload will be also sent to the server.

```swift
let event = Event(type: Application.DidFinishLaunching, payload: ["url": "example.com"])
```

### Custom types

In order to send custom types for your events, you can create a `Type` subclass. Below a snippet to have convenience initializers.

```swift
class Rate : Type {
    static let Great = Rate(subtype: "Great")
    static let Average = Rate(subtype: "Average")
    static let Bad = Rate(subtype: "Bad")
}
```

and a new `Event` can be created

```swift
let event = Event(Rate.Great)
```

You can also specify a custom image to be associated with the `Type`. Please take a look at the `SampleType` class included in the sample project.

### Events View Controller

There's also a convenience `EventsTableViewController` (embedded in a `UINavigationController`) that can be instantiated and presented modally from your application to identify and inspect the events.

```swift
let desmanStoryboard = UIStoryboard(name: "Desman", bundle: NSBundle(forClass: EventManager.self))
let desmanController = desmanStoryboard.instantiateViewControllerWithIdentifier("eventsController")
self.presentViewController(desmanController, animated: true, completion: nil)
```

## Acknowledgements

Matteo Gavagnin [@macteo](http://twitter.com/macteo) - [DIMENSION](http://www.dimension.it)
