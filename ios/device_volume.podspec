#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint device_volume.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'device_volume'
  s.version          = '0.0.1'
  s.summary          = 'Control device volume from Flutter via FFI.'
  s.description      = <<-DESC
Flutter FFI plugin for reading and observing the device volume on iOS
using AVAudioSession. Write operations are not available on iOS due to
App Store policy restrictions.
                       DESC
  s.homepage         = 'https://github.com/arcas0803/device_volume'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'ArcasHH' => 'alvaroarcasgarcia@gmail.com' }

  # This will ensure the source files in Classes/ are included in the native
  # builds of apps using this FFI plugin. Podspec does not support relative
  # paths, so Classes contains a forwarder C file that relatively imports
  # `../src/*` so that the C sources can be shared among all target platforms.
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'
  s.frameworks = 'AVFoundation', 'MediaPlayer'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
