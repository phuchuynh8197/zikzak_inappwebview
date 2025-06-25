#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutterplugintest.podspec' to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'zikzak_inappwebview_ios'
  s.module_name      = 'zikzak_inappwebview_ios'
  s.version          = '2.4.8'
  s.summary          = 'iOS implementation of the inappwebview plugin for Flutter.'
  s.description      = <<-DESC
    iOS implementation of the Flutter inappwebview plugin. A feature-rich WebView plugin for Flutter applications with support for iOS 13.0+. This plugin provides a powerful WebView widget with extensive customization options and JavaScript communication capabilities.
  DESC

  s.homepage         = 'http://zikzak.wtf'
  s.license          = { :type => 'Apache-2.0', :file => '../LICENSE' }
  s.author           = { 'ARRRRNY' => 'arrrrny@zikzak.wtf' }

  s.source           = { :git => 'https://github.com/phuchuynh8197/zikzak_inappwebview.git', :tag => s.version.to_s }

  # 💥 Đường dẫn này cần KHỚP với nơi chứa file `.m`, `.h`
  s.source_files     = 'ios/Classes/**/*.{h,m,swift}'
  s.public_header_files = 'ios/Classes/**/*.h'
  s.resources        = 'ios/Storyboards/**/*.storyboard'

  s.dependency 'Flutter'
  s.dependency 'OrderedSet', '>= 6.0.3'

  s.frameworks = 'WebKit'
  s.swift_version = '5.9'
  s.platforms = { :ios => '13.0' }

  s.default_subspec = 'Core'
  s.subspec 'Core' do |core|
    core.platform = :ios, '13.0'
  end

  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'IPHONEOS_DEPLOYMENT_TARGET' => '13.0'
  }
end
