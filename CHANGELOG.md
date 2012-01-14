2012-01-13 wooster
------------------
* Start of version 0.2.
* Added support for adding and removing initial data to feedback.
* Added initial version of metrics module.
* Added support for optionally showing or hiding the email address field on feedback.
* Added support for setting an initial email address on the feedback form.

To add data to feedback, use these methods on `ATConnect`:

``` objective-c
- (void)addAdditionalInfoToFeedback:(NSObject<NSCoding> *)object withKey:(NSString *)key;
- (void)removeAdditionalInfoFromFeedbackWithKey:(NSString *)key;
```

The data objects should, at this time, either be of type `NSString` or `NSDate`. They will be added to the `record[data]` hash, with the key as the key, as in `record[data][key]`.

If you add the metrics module to your project, it will load on run. It's experimental at this point, so I wouldn't recommend using it quite yet.

You can use these properties to control email field behavior on the feedback form:

``` objective-c
@property (nonatomic, assign) BOOL showEmailField;
@property (nonatomic, retain) NSString *initialEmailAddress;
```

`showEmailField` controls whether or not the email address field is shown on the feedback form. `initialEmailAddress` can be used to set the initial email address that populates the field. Note: if the user submits feedback with a different email address, `initialEmailAddress` will not be used.