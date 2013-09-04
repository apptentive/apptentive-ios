Pod::Spec.new do |s|
  s.name     = 'apptentive-ios'
  s.version  = '1.1.0'
  s.license  = 'BSD'
  s.summary  = 'Apptentive Customer Communications SDK.'
  s.homepage = 'https://www.apptentive.com/'
  s.author   = { "Andrew Wooster" => "andrew@apptentive.com" }
  s.source   = { :git => 'git@github.com:apptentive/apptentive-ios.git', :tag => "#{s.version}" }
  s.platform = :ios, '4.3'
  s.source_files   = 'source/**/*.{h,m}','ext/**/*.{h,m}'
  s.exclude_files = 'ext/PrefixedTTTAttributedLabel/Example/*.*'
  s.requires_arc = false
  s.frameworks     = 'CoreGraphics', 'Foundation', 'QuartzCore', 'SystemConfiguration', 'UIKit', 'CoreData', 'CoreText'
  s.resources = 'xibs/**/*.*', 'resources/localization/*.*', 'source/Model/*.xcdatamodeld', 'art/generated'
  s.resource_bundle = { 'ApptentiveResources' => 'source/Model/*.xcdatamodeld' }
  s.weak_frameworks = 'StoreKit', 'CoreTelephony'
  s.prefix_header_contents = '#import "ATLog.h"'
  s.xcconfig = { "GCC_PREPROCESSOR_DEFINITIONS" =>  "TTTATTRIBUTEDLABEL_PREFIX=AT  JSONKIT_PREFIX=AT APPTENTIVE_DEBUG_LOG_VIEWER=1 AT_LOGGING_LEVEL_INFO=1 AT_LOGGING_LEVEL_ERROR=1" }
end
