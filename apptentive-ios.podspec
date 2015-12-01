Pod::Spec.new do |s|
  s.name     = 'apptentive-ios'
  s.version  = '2.1'
  s.license  = 'BSD'
  s.summary  = 'Apptentive Customer Communications SDK.'
  s.homepage = 'https://www.apptentive.com/'
  s.authors  = { "Andrew Wooster" => "andrew@apptentive.com",
                 "Peter Kamb" => "peter@apptentive.com",
                 "Frank Schmitt" => "frank@apptentive.com" }
  s.source   = { :git => 'https://github.com/apptentive/apptentive-ios.git', :tag => "v#{s.version}" }
  s.platform = :ios, '7.0'
  s.source_files   = 'ApptentiveConnect/source/**/*.{h,m}','ApptentiveConnect/ext/**/*.{h,m}'
  s.requires_arc = true
  s.frameworks     = 'AssetsLibrary', 'AVFoundation', 'CoreGraphics', 'Foundation', 'ImageIO', 'MobileCoreServices', 'QuartzCore', 'SystemConfiguration', 'UIKit', 'CoreData'
  s.resource_bundle = { 'ApptentiveResources' => [
		'ApptentiveConnect/source/Model/*.xcdatamodeld',
		'ApptentiveConnect/source/Model/*.xcmappingmodel',
		'ApptentiveConnect/resources/localization/*.lproj',
		'ApptentiveConnect/resources/images/**/*.*',
		'ApptentiveConnect/resources/Apptentive.storyboard',
		'ApptentiveConnect/resources/CocoaPodsResources/Info.plist'
		] }
  s.weak_frameworks = 'StoreKit', 'CoreTelephony'
  s.prefix_header_contents = '#import "ATLog.h"'
  s.xcconfig = { "GCC_PREPROCESSOR_DEFINITIONS" => "AT_LOGGING_LEVEL_ERROR=1" }
end
