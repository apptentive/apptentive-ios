### Get Apptentive

All of our client code is open source and available on GitHub](https://github.com/apptentive/apptentive-ios).

#### Using Git

You can clone our iOS SDK using git: `git clone https://github.com/apptentive/apptentive-ios.git`.

### Add Apptentive as Xcode Subproject

When the Apptentive submodule has finished cloning, it should be added to your Xcode project or workspace as a subproject.

Drag the `ApptentiveConnect.xcodeproj` project file (located in the `ApptentiveConnect` folder of our source code) into your Xcode project.

![ApptentiveConnect drag](https://raw.github.com/apptentive/apptentive-ios/master/etc/screenshots/iOS-apptentive-connect.png)

------------------------------------------------------------------------------------

### Required Frameworks

To use `ApptentiveConnect`, your project must link against the following frameworks:

* Accelerate
* AssetsLibrary
* CoreData
* CoreText
* CoreGraphics
* CoreTelephony
* Foundation
* QuartzCore
* StoreKit
* SystemConfiguration
* UIKit

*Note:* If your app uses Core Data and you listen for Core Data related notifications, you will
want to filter them based upon your managed object context. Learn more from [Apple's documentation](https://developer.apple.com/library/mac/#documentation/Cocoa/Reference/CoreDataFramework/Classes/NSManagedObjectContext_Class/NSManagedObjectContext.html).

##### Add required Frameworks

1. Select your Xcode project in the file navigator sidebar.
2. Select your Target, then its "Build Phases" tab.
3. Expand the "Link Binary With Libraries" build phase.
4. Add the frameworks listed above by clicking the `+` button.

![iOS Frameworks](https://raw.github.com/apptentive/apptentive-ios/master/etc/screenshots/iOS-frameworks.png)

### Add Linker Flags

1. Select your Xcode project in the file navigator sidebar.
2. Select your Project, then its "Build Settings" tab.
3. Search for the "Other Linker Flags" setting.
4. Double click the `Other Linker Flags` row's value area, on the right side. A pop-up should appear.
5. Add the following linker flags by pressing the "+" button:

```
    -ObjC -all_load
```

![iOS Linker Flags](https://raw.github.com/apptentive/apptentive-ios/master/etc/screenshots/iOS-linker-flags.png)

**Note:** If you can't use the `-all_load` flag in your project, you can use the `-force_load` flag instead:

```
    -force_load $(BUILT_PRODUCTS_DIR)/libApptentiveConnect.a
```

### Add Apptentive Library and Resources

##### Add Target Dependencies

1. Return to your Target's "Build Phases" tab.
2. Expand the "Target Dependencies" build phase.
3. Add `ApptentiveConnect` and `ApptentiveResources` as target dependencies.

![iOS Target Dependencies](https://raw.github.com/apptentive/apptentive-ios/master/etc/screenshots/iOS-target-dependencies.png)

##### Link Apptentive Library

1. Expand the "Link Binary With Libraries" build phase.
2. Click the "+" button and add `libApptentiveConnect.a`

![Apptentive Library](https://raw.github.com/apptentive/apptentive-ios/master/etc/screenshots/iOS-apptentive-library.png)

##### Build Apptentive Resources bundle

You should now build `ApptentiveResources.bundle`, the Apptentive assets bundle that will be added to your app.

1. In the upper left corner of your Xcode window, select the `Apptentive Resources` target from the scheme picker.
2. Select `iOS Device` as the build destination.
3. Select `Product > Build` from your Mace's menu bar.

**Note:** Build for an iOS Device, not the iOS Simulator, to work around an Xcode bug.

##### Copy Apptentive Resources bundle

1. Expand the ApptentiveConnect project in Xcode's file navigator.
2. Expand the `Products` directory. It should contain `ApptentiveResources.bundle`.
3. If the bundle's label is red, it must first be built. Follow the steps in the previous section.
3. In your Xcode Target's `Build Phases`, expand the `Copy Bundle Resources` build phase.
4. Drag `ApptentiveResources.bundle` from the `ApptentiveConnect` directory into the `Copy Bundle Resources` area.

![iOS Bundle Resources](https://raw.github.com/apptentive/apptentive-ios/master/etc/screenshots/iOS-bundle-resources.png)

### Add Apptentive header files

1. In the file navigator, expand the `source` directory of the ApptentiveConnect project.
2. Drag the file `ATConnect.h` into to your app's file list.

-
