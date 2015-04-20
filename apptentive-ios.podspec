Pod::Spec.new do |s|
  s.name     = 'Apptentive'
  s.module_name = 'Apptentive'
  s.public_header_files = ['ApptentiveConnect/source/ATConnect.h']
  s.version  = '2.Swift'
  s.license  = 'BSD'
  s.summary  = 'Apptentive Customer Communications SDK.'
  s.homepage = 'https://www.apptentive.com/'
  s.authors  = { "Andrew Wooster" => "andrew@apptentive.com",
                 "Peter Kamb" => "peter@apptentive.com",
                 "Frank Schmitt" => "frank@apptentive.com"}
  s.source   = { :git => 'https://github.com/apptentive/apptentive-ios.git', :tag => "v#{s.version}" }
  s.platform = :ios, '8.0'
  s.source_files   = 'ApptentiveConnect/source/**/*.{h,m}','ApptentiveConnect/ext/**/*.{h,m}'
  s.exclude_files = 'ApptentiveConnect/ext/PrefixedTTTAttributedLabel/**/*.*'
  s.subspec 'arc-files' do |sna|
    sna.requires_arc = true
    sna.source_files = 'ApptentiveConnect/ext/PrefixedTTTAttributedLabel/TTTAttributedLabel/*.{h,m}'
    sna.prefix_header_contents = ''
  end
  s.requires_arc = false
  s.frameworks     = 'Accelerate', 'AssetsLibrary', 'CoreGraphics', 'Foundation', 'QuartzCore', 'SystemConfiguration', 'UIKit', 'CoreData', 'CoreText'
  s.resource_bundle = { 'ApptentiveResources' => ['ApptentiveConnect/source/Model/*.xcdatamodeld', 'ApptentiveConnect/xibs/**/*.*', 'ApptentiveConnect/resources/localization/*.lproj','ApptentiveConnect/art/generated/**/*.*', 'ApptentiveConnect/resources/CocoaPodsResources/Info.plist'] }
  s.weak_frameworks = 'StoreKit', 'CoreTelephony'
  s.prefix_header_contents = '#import "ATLog.h"'
  s.xcconfig = { "GCC_PREPROCESSOR_DEFINITIONS" => "TTTATTRIBUTEDLABEL_PREFIX=AT AT_LOGGING_LEVEL_ERROR=1" }
end
