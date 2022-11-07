source 'https://github.com/CocoaPods/Specs.git'

platform :ios, '13.0'

use_frameworks!

def shared_pods
  pod 'ExpoFpCommon', '0.3.2'
  #pod 'ExpoFpCommon', :path => '/Users/vladimir/Xcode projects/expofp-common-ios'
end

target 'ExpoFpFplan' do
  shared_pods
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
      config.build_settings['IPHONESIMULATOR_DEPLOYMENT_TARGET'] = '13.0'
    end
  end
end
