Pod::Spec.new do |s|
  s.name             = 'app_minimizer_plus'
  s.version          = '0.0.1'
  s.summary          = 'A Flutter plugin to minimize the iOS application using Pigeon.'
  s.description      = <<-DESC
A Flutter plugin to minimize the iOS application using Pigeon.
                       DESC
  s.homepage         = 'https://github.com/openci-org/openci'
  s.license          = { :type => 'BSD', :file => '../LICENSE' }
  s.author           = { 'OpenCI' => 'contact@open-ci.io' }
  s.source           = { :path => '.' }
  s.source_files = 'app_minimizer_plus/Sources/app_minimizer_plus/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
