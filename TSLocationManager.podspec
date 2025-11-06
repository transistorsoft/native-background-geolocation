Pod::Spec.new do |s|
  s.name         = 'TSLocationManager'
  s.version      = '4.0.0-beta.1'
  s.summary      = 'Enterprise-grade background geolocation.'
  s.description  = 'Reliable background location with SQLite-first persistence and robust HTTP uploader.'
  s.homepage     = 'https://transistorsoft.com'
  s.license      = { :type => 'Commercial', :file => 'LICENSE' }
  s.author       = { 'Transistor Software' => 'info@transistorsoft.com' }
  s.source       = { :http => 'https://github.com/transistorsoft/native-background-geolocation/releases/download/4.0.0-beta.1/TSLocationManager.xcframework.zip' }
  s.ios.deployment_target = '12.0'
  s.vendored_frameworks   = 'TSLocationManager.xcframework'
  s.static_framework      = true
  s.frameworks            = 'CoreLocation', 'SystemConfiguration', 'CoreTelephony'
  s.weak_frameworks       = 'BackgroundTasks'
  s.libraries             = 'sqlite3', 'z', 'c++'
  s.pod_target_xcconfig   = { 'BUILD_LIBRARY_FOR_DISTRIBUTION' => 'YES' }
end
