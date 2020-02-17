#
# Be sure to run `pod lib lint Chinook.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'Chinook'
  s.version          = '0.1.0'
  s.summary          = 'A short description of Chinook.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/gpkash/Chinook'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'gpkash' => 'capikaw@gmail.com' }
  s.source           = { :git => 'https://github.com/gpkash/Chinook.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/capikaw'
  s.ios.deployment_target = '9.0'
  s.swift_version = '5.1'
  s.source_files = 'Chinook/Classes/**/*'

  s.dependency 'XMLCoder', '~> 0.9.0'
end
