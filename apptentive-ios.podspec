Pod::Spec.new do |s|
  s.name     = 'apptentive-ios'
  s.module_name = 'Apptentive'
  s.version  = '3.1.1'
  s.license  = 'BSD'
  s.summary  = 'Apptentive Customer Communications SDK.'
  s.homepage = 'https://www.apptentive.com/'
  s.authors  = { 'Apptentive SDK Team' => 'sdks@apptentive.com' }
  s.source   = { :git => 'https://github.com/apptentive/apptentive-ios.git', :tag => "v#{s.version}" }
  s.platform = :ios, '7.0'
  s.source_files   = 'ApptentiveConnect/source/**/*.{h,m}'
  s.requires_arc = true
  s.frameworks     = 'AVFoundation', 'CoreData', 'CoreGraphics', 'Foundation', 'ImageIO', 'MobileCoreServices', 'QuartzCore', 'QuickLook', 'SystemConfiguration', 'UIKit'
  s.resource_bundle = { 'ApptentiveResources' => [
		'ApptentiveConnect/source/Model/*.xcdatamodeld',
		'ApptentiveConnect/source/Model/*.xcmappingmodel',
		'ApptentiveConnect/resources/localization/*.lproj',
		'ApptentiveConnect/resources/images/**/*.*',
		'ApptentiveConnect/resources/Apptentive.storyboard',
		'ApptentiveConnect/resources/CocoaPodsResources/Info.plist'
		] }
  s.weak_frameworks = 'StoreKit', 'CoreTelephony'
  s.prefix_header_contents = '#import "ApptentiveLog.h"'
  s.xcconfig = { "GCC_PREPROCESSOR_DEFINITIONS" => "APPTENTIVE_LOGGING_LEVEL_ERROR=1" }
  s.public_header_files = 'ApptentiveConnect/source/Apptentive.h', 'ApptentiveConnect/source/ApptentiveStyleSheet.h', 'ApptentiveConnect/source/Apptentive+Debugging.h'
end
