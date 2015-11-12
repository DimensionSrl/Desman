Pod::Spec.new do |s|
  s.name                  = 'Desman'
  s.version               = '0.1.3'
  s.summary               = 'An event tracking tool for mobile apps.'
  s.homepage              = 'http://desman.dimension.it'
  s.license               = 'MIT'
  s.author                = { 'Matteo Gavagnin' => 'm@macteo.it' }
  s.social_media_url      = 'http://twitter.com/macteo'
  s.ios.deployment_target = '8.0'
  s.source                = { :git => 'http://10.10.1.4/ios/desman.git', :tag => s.version }
  s.requires_arc          = true
  s.default_subspec       = 'Core'
  
  s.subspec 'Core' do |core|
    core.framework        = 'Photos'
    core.source_files     = 'Desman/**/*.swift'
    core.resources        = ['Desman/**/*.xcassets', 'Desman/Interface/*.storyboard']
  end
  
  s.subspec 'Realtime' do |realtime|
    realtime.framework    = 'Photos'
    realtime.source_files = 'Desman/**/*.swift'
    realtime.resources    = ['Desman/**/*.xcassets', 'Desman/Interface/*.storyboard']  
    realtime.xcconfig	  = { 'OTHER_CFLAGS' => '$(inherited) -DDESMAN_INCLUDES_REALTIME' }
    realtime.library      = 'z'
    realtime.dependency 'SwiftWebSocket', '~> 2.3.0'
  end
end