Pod::Spec.new do |s|
  s.name     = 'GeoJSONSerialization'
  s.version  = '0.0.4'
  s.license  = 'MIT'
  s.summary  = 'Encodes and decodes between MapKit shapes and GeoJSON.'
  s.homepage = 'https://github.com/mattt/GeoJSONSerialization'
  s.social_media_url = 'https://twitter.com/mattt'
  s.authors  = { 'Mattt' => 'mattt@me.com' }
  s.source   = { :git => 'https://github.com/mattt/GeoJSONSerialization.git', :tag => s.version }
  s.source_files = 'GeoJSONSerialization'
  s.requires_arc = true

  s.frameworks = "MapKit", "CoreLocation"

  s.ios.deployment_target = '6.0'
  s.osx.deployment_target = '10.9'
end
