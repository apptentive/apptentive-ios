#### Using CocoaPods

The Apptentive iOS SDK is available via CocoaPods, a dependency manager for Objective-C.

http://cocoapods.org/

##### Create project Podfile

Your Podfile controls the dependencies that CocoaPods installs in your Xcode project:  

1. Create a text file named "Podfile" in your Xcode project directory.
2. Find [Apptentive's pod information](http://cocoapods.org/?q=apptentive-ios) on [CocoaPods](http://cocoapods.org).
3. Add the Apptentive dependency to your Podfile. It should look something like this:

```
platform :ios, '7.0'
pod 'apptentive-ios'
```

##### Install the Apptentive Pod

When the Apptentive dependency has been listed in your Podfile, run the Terminal command `pod install` in your Xcode project directory:

```
$ pod install
```

If all goes well, you should see:

 > [!] From now on use `YourProject.xcworkspace`.
 
CocoaPods has created an Xcode Workspace containing your original project plus a project containing Apptentive your other project dependencies.
 
##### Begin using Apptentive

After running `pod install`, open the newly created Xcode Workspace.

You can now begin using Apptentive. For example, set your API key:  

```
#import "ATConnect.h"
...
[ATConnect sharedConnection].apiKey = @"abc_xyz_abc_xyz";
```

-