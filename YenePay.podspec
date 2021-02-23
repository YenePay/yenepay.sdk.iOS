#
# Be sure to run `pod lib lint YenePay.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'YenePay'
  s.version          = '1.0.1'
  s.summary          = 'YenePay SDK for iOS.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
  "YenePay SDK for iOS will let you connect your app with YenePay to start accepting payments."
                       DESC

  s.homepage         = 'https://github.com/YenePay/yenepay.sdk.iOS'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'ahmed' => 'ahmed.mohammed@yenepay.com' }
  s.source           = { :git => 'https://github.com/YenePay/yenepay.sdk.iOS.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '10.0'

  s.source_files = 'YenePay/Classes/*', 'YenePay/Private/*'
  
  # s.resource_bundles = {
  #   'YenePay' => ['YenePay/Assets/*.png']
  # }

  s.public_header_files = 'YenePay/Classes/**/*.h'
  s.private_header_files = 'YenePay/Private/**/*.h'
  
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
