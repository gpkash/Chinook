Pod::Spec.new do |s|
  s.name             = 'Chinook'
  s.version          = '0.0.7'
  s.summary          = 'Simplified interactions to Environment Canada weather API.'
  s.homepage         = 'https://github.com/gpkash/Chinook'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Gary Kash' => 'capikaw@gmail.com' }
  s.source           = { :git => 'git@github.com:gpkash/Chinook.git', :tag => s.version.to_s }
  s.source_files     = "Chinook/Classes/**/*.swift"

  s.swift_version = '6.1'
  s.ios.deployment_target = "15.0"
  s.tvos.deployment_target = "15.0"

  s.dependency 'XMLCoder', '~> 0.9.0'

end
