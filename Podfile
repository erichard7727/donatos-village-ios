using_bundler = defined? Bundler
unless using_bundler
  puts "\nPlease re-run using:".red
  puts "  bundle exec pod install\n\n"
  exit(1)
end

source 'https://github.com/CocoaPods/Specs.git'

use_frameworks!
inhibit_all_warnings!

workspace 'Village'
project './Product/Core/VillageCore/VillageCore.xcodeproj'
project './Product/Core/VillageCoreUI/VillageCoreUI.xcodeproj'
project './Clients/DonatosVillage/DonatosVillage.xcodeproj'

def core_pods
  pod 'PromisesSwift'
  pod 'Moya'
  pod 'SwiftyJSON'
  pod 'SwiftWebSocket', :git => 'https://github.com/tidwall/SwiftWebSocket', :branch => 'master'
end

def core_ui_pods
  pod 'Nantes'
  pod 'AlamofireImage'
  pod 'SlackTextViewController'
  pod 'DZNEmptyDataSet'
end

def client_pods
  pod 'AppCenter'
  pod 'Fabric'
  pod 'Crashlytics'
  pod 'Firebase/Core'
end

target 'VillageCore' do
  platform :ios, '11'
  project './Product/Core/VillageCore/VillageCore.xcodeproj'

  core_pods
end

target 'VillageCoreUI' do
  platform :ios, '11'
  project './Product/Core/VillageCoreUI/VillageCoreUI.xcodeproj'

  core_pods
  core_ui_pods
  
end

target 'DonatosVillage' do
  platform :ios, '11'
  project './Clients/DonatosVillage/DonatosVillage.xcodeproj'

  core_pods
  core_ui_pods
  client_pods
  
end

post_install do |installer|

	# Workaround for Cocoapods issue #7606 (CoocaPods v1.5.0 breaks IBDesignables)
	installer.pods_project.build_configurations.each do |config|
        config.build_settings.delete('CODE_SIGNING_ALLOWED')
        config.build_settings.delete('CODE_SIGNING_REQUIRED')
    end

	# Manually manage specific pod versions (like when upgrading Swift versions)
#    installer.pods_project.targets.each do |target|
#        target.build_configurations.each do |config|
##            config.build_settings['SWIFT_VERSION'] = '4.0'
#            if target.name == 'R.swift.Library'
#                config.build_settings['SWIFT_VERSION'] = '4.1'
#            end
#        end
#    end

end
