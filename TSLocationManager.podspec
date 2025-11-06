Pod::Spec.new do |s|
  s.name         = 'TSLocationManager'
  s.version      = '4.0.0-beta.1'
  s.summary      = 'Enterprise-grade background geolocation.'
  s.description  = 'Reliable background location with SQLite-first persistence and robust HTTP uploader.'
  s.homepage               = 'https://www.transistorsoft.com'
  s.license                = { :type => 'Commercial', :text => 'Proprietary software. © Transistor Software. All rights reserved. License terms: https://www.transistorsoft.com/shop/products/native-background-geolocation/license' }
  s.author       = { 'Transistor Software' => 'info@transistorsoft.com' }
  s.source       = { :http => 'https://github.com/transistorsoft/native-background-geolocation/releases/download/4.0.0-beta.1/TSLocationManager.xcframework.zip' }
  s.ios.deployment_target = '12.0'
  s.vendored_frameworks   = 'TSLocationManager.xcframework'
  s.static_framework      = true
  s.frameworks            = 'CoreLocation', 'SystemConfiguration', 'CoreTelephony'
  s.weak_frameworks       = 'BackgroundTasks'
  s.libraries             = 'sqlite3', 'z', 'c++'
  s.pod_target_xcconfig   = { 'BUILD_LIBRARY_FOR_DISTRIBUTION' => 'YES' }
  s.documentation_url      = 'https://www.transistorsoft.com/background-geolocation'
  s.social_media_url       = 'https://x.com/transistorsoft'
end