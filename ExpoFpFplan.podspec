Pod::Spec.new do |spec|
  spec.name               = "ExpoFpFplan"
  spec.version            = "4.2.13"
  spec.platform           = :ios, '14.0'
  spec.summary            = "ExpoFP UIFplanView & FplanView"
  spec.description        = "UIFplanView and FplanView for ExpoFP SDK"
  spec.homepage           = "https://www.expofp.com"
  spec.documentation_url  = "https://expofp.github.io/expofp-mobile-sdk/ios-sdk"
  spec.license            = { :type => "MIT", :file => "LICENSE.md" }
  spec.author                = { 'ExpoFP' => 'support@expofp.com' }
  spec.source             = { :git => 'https://github.com/expofp/expofp-fplan-ios.git', :tag => "#{spec.version}" }
  spec.swift_version      = "5"

  # Supported deployment targets
  spec.ios.deployment_target  = "14.0"

  # Published binaries
  spec.ios.vendored_frameworks = "ExpoFpFplan.xcframework"

  # Add here any resources to be exported.
  spec.dependency 'ExpoFpCommon', '4.2.13'
  spec.dependency 'ZIPFoundation', '~> 0.9.16'

end
