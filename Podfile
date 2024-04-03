# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

target 'FlashThoughts' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for FlashThoughts
  pod 'MBProgressHUD', '~> 1.2.0'

  pod 'Firebase/Database'
  pod 'Firebase/Auth'
  pod 'GoogleSignIn'
end

post_install do |installer|
  installer.generated_projects.each do |project|
    project.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
    end

    project.targets.each do |target|
      target.build_configurations.each do |config|
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
      end
    end
  end
end

