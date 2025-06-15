#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutterplugintest.podspec' to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'zikzak_inappwebview_ios'
  s.version          = '2.4.1'
  s.summary          = 'IOS implementation of the inappwebview plugin for Flutter.'
  s.description      = <<-DESC
A new Flutter plugin.
                       DESC
  s.homepage         = 'http://zikzak.wtf'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'ARRRRNY' => 'arrrrny@zikzak.wtf' }
  s.source           = { :git => 'https://github.com/arrrrny/zikzak_inappwebview.git', :tag => s.version.to_s }
  s.source_files = 'Classes/**/*'
  s.resources = 'Storyboards/**/*.storyboard'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'

  # Flutter.framework does not contain a i386 slice. Only x86_64 simulators are supported.
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
  }

  # Removed obsolete Swift overlay libraries

  # Removed obsolete LIBRARY_SEARCH_PATHS for Swift overlays

  s.frameworks = 'WebKit'

  s.swift_version = '5.9'

  s.platforms = { :ios => '13.0' }
  s.dependency 'OrderedSet', '~>5.0'

  s.default_subspec = 'Core'

  s.subspec 'Core' do |core|
    core.platform = :ios, '13.0'
  end
end
