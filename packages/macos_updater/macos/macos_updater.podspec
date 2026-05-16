#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint macos_updater.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'macos_updater'
  s.version          = '0.0.1'
  s.summary          = 'A macOS-only Flutter plugin for Sparkle-based app updates.'
  s.description      = <<-DESC
A macOS-only Flutter plugin for Sparkle-based app updates.
                       DESC
  s.homepage         = 'https://github.com/openci-org/openci'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'OpenCI' => 'info@openci.org' }

  s.source           = { :path => '.' }
  s.source_files = 'macos_updater/Sources/macos_updater/**/*'

  # If your plugin requires a privacy manifest, for example if it collects user
  # data, update the PrivacyInfo.xcprivacy file to describe your plugin's
  # privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'macos_updater_privacy' => ['macos_updater/Sources/macos_updater/PrivacyInfo.xcprivacy']}

  s.dependency 'FlutterMacOS'
  s.dependency 'Sparkle', '~> 2.9'

  s.platform = :osx, '10.13'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
