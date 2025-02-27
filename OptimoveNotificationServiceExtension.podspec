Pod::Spec.new do |s|
  s.name             = 'OptimoveNotificationServiceExtension'
  s.version          = '3.5.4'
  s.summary          = 'Official Optimove SDK for iOS. Notification service extension framework.'
  s.description      = 'The notification service extension is used for handling notifications.'
  s.homepage         = 'https://github.com/optimove-tech/Optimove-SDK-iOS'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Mobius Solutions' => 'mobile@optimove.com' }
  s.source           = { :git => 'https://github.com/optimove-tech/Optimove-SDK-iOS.git', :tag => s.version.to_s }
  s.platform = 'ios'
  s.ios.deployment_target = '10.0'
  s.swift_version = '5'
  base_dir = "OptimoveNotificationServiceExtension/"
  s.source_files = base_dir + 'Sources/Classes/**/*'
  s.dependency 'OptimoveCore', s.version.to_s
  s.frameworks = 'Foundation', 'UserNotifications', 'UIKit'
  s.test_spec 'unit' do |unit_tests|
    unit_tests.source_files = base_dir + 'Tests/Sources/**/*', 'Shared/Tests/Sources/**/*'
    unit_tests.resources = base_dir + 'Tests/Resources/**/*', 'Shared/Tests/Resources/**/*'
  end
end
