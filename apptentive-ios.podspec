Pod::Spec.new do |s|
  s.name     = 'apptentive-ios'
  s.module_name = 'Apptentive'
  s.version  = '3.3.1'
  s.license  = 'BSD'
  s.summary  = 'Apptentive Customer Communications SDK.'
  s.homepage = 'https://www.apptentive.com/'
  s.authors  = { 'Apptentive SDK Team' => 'sdks@apptentive.com' }
  s.source   = { :git => 'https://github.com/apptentive/apptentive-ios.git', :tag => "v#{s.version}" }
  s.platform = :ios, '8.0'
  s.source_files   = 'ApptentiveConnect/source/**/*.{h,m}'
  s.requires_arc = true
  s.frameworks     = 'AVFoundation', 'CoreData', 'CoreGraphics', 'Foundation', 'ImageIO', 'MobileCoreServices', 'QuartzCore', 'QuickLook', 'SystemConfiguration', 'UIKit'
  s.resource_bundle = { 'ApptentiveResources' => [
		'ApptentiveConnect/source/Model/*.xcdatamodeld',
		'ApptentiveConnect/source/Model/*.xcmappingmodel',
		'ApptentiveConnect/resources/localization/*.lproj',
		'ApptentiveConnect/resources/images/**/*.*',
		'ApptentiveConnect/resources/Apptentive.storyboard'
		] }
  s.weak_frameworks = 'StoreKit', 'CoreTelephony'
  s.prefix_header_contents = '#import "ApptentiveLog.h"'
  s.pod_target_xcconfig = { "GCC_PREPROCESSOR_DEFINITIONS[config=Debug]" => "APPTENTIVE_LOGGING_LEVEL_DEBUG=1 APPTENTIVE_LOGGING_LEVEL_INFO=1 APPTENTIVE_LOGGING_LEVEL_WARNING=1 APPTENTIVE_LOGGING_LEVEL_ERROR=1 APPTENTIVE_COCOAPODS=1",
  "GCC_PREPROCESSOR_DEFINITIONS[config=Release]" => "APPTENTIVE_LOGGING_LEVEL_INFO=1 APPTENTIVE_LOGGING_LEVEL_WARNING=1 APPTENTIVE_LOGGING_LEVEL_ERROR=1 APPTENTIVE_COCOAPODS=1" }
  s.public_header_files = 'ApptentiveConnect/source/Apptentive.h', 'ApptentiveConnect/source/ApptentiveStyleSheet.h'

	s.subspec 'Debug' do |sp|
	  sp.source_files = [ 'ApptentiveConnect/debug/*.{h,m}', 'ApptentiveConnect/source/Apptentive_Private.h' ]
	end
end
