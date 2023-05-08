Pod::Spec.new do |spec|
  spec.name               = "ExpoFpFplan"
  spec.version            = "4.0.0"
  spec.platform           = :ios, '14.0'
  spec.summary            = "Fplan Library for iOS apps"
  spec.description        = "Library for displaying expo plans"
  spec.homepage           = "https://www.expofp.com"
  spec.documentation_url  = "https://github.com/expofp/expofp-sdk-ios"
  spec.license            = { :type => "MIT" }
  spec.author                = { 'ExpoFP' => 'support@expofp.com' }
  spec.source             = { :git => 'https://github.com/expofp/expofp-fplan-ios.git', :tag => "#{spec.version}" }
  spec.swift_version      = "5"

  # Supported deployment targets
  spec.ios.deployment_target  = "14.0"

  # Published binaries
  spec.ios.vendored_frameworks = "xcframework/ExpoFpFplan.xcframework"

  # Add here any resources to be exported.
  spec.dependency 'ExpoFpCommon', '4.0.0'

end
