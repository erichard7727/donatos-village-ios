using_bundler = defined? Bundler
unless using_bundler
  puts "\nPlease re-run using:".red
  puts "  bundle exec pod install\n\n"
  exit(1)
end

#source 'https://github.com/CocoaPods/Specs.git'
#source 'https://cdn.jsdelivr.net/cocoa/'
source 'https://cdn.cocoapods.org/'

#install! 'cocoapods',
#    :generate_multiple_pod_projects => true,
#    :incremental_installation => true

platform :ios, '11'
use_frameworks!
#use_modular_headers!
inhibit_all_warnings!

workspace 'Village'
project './Product/Core/VillageCore/VillageCore.xcodeproj'
project './Product/Core/VillageCoreUI/VillageCoreUI.xcodeproj'
project './Clients/DonatosVillage/DonatosVillage.xcodeproj'

def core_pods
  pod 'PromisesSwift'
  pod 'PromisesObjC', :modular_headers => true
  pod 'Moya'
  pod 'SwiftyJSON'
  pod 'SwiftWebSocket', :git => 'https://github.com/tidwall/SwiftWebSocket', :branch => 'master'
  pod 'Differ'
  pod 'KeychainAccess'
end

def core_ui_pods
  pod 'Nantes', :git => 'https://github.com/instacart/Nantes', :branch => 'master' #pointing to master branch until version > v0.0.8 is available
  pod 'AlamofireImage'
  pod 'MessageViewController'
  pod 'DZNEmptyDataSet', :modular_headers => true
end

def client_pods
  pod 'AppCenter'
  pod 'Fabric'
  pod 'Crashlytics'
  pod 'Firebase/Core'
end

target 'VillageCore' do
  project './Product/Core/VillageCore/VillageCore.xcodeproj'
  core_pods
end

target 'VillageCoreUI' do
  project './Product/Core/VillageCoreUI/VillageCoreUI.xcodeproj'
  core_pods
  core_ui_pods
end

target 'DonatosVillage' do
  project './Clients/DonatosVillage/DonatosVillage.xcodeproj'
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
