Pod::Spec.new do |s|
  s.name = 'openci_virtual_ble'
  s.version = '0.1.0'
  s.summary = 'Debug simulator client for OpenCI virtual GATT.'
  s.homepage = 'https://github.com/openci-org/openci'
  s.license = { :type => 'Apache-2.0', :file => '../LICENSE' }
  s.author = 'OpenCI'
  s.source = { :path => '.' }
  s.source_files = 'openci_virtual_ble/Sources/openci_virtual_ble/**/*.swift'
  s.dependency 'Flutter'
  s.platform = :ios, '15.0'
  s.swift_version = '5.0'
end
