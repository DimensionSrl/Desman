Pod::Spec.new do |s|
  s.name                  = 'Desman'
  s.version               = '0.2.0'
  s.summary               = 'An event tracking tool for mobile apps.'
  s.homepage              = 'http://desman.dimension.it'
  s.license               = 'MIT'
  s.authors               = [ 'Matteo Gavagnin' => 'm@macteo.it', 'Dimension S.r.l.' => 'info@dimension.it' ]
  s.social_media_url      = 'http://twitter.com/macteo'
  s.ios.deployment_target = '8.0'
  s.source                = { :git => 'http://10.10.1.4/ios/desman.git', :tag => "v#{s.version}" }
  s.requires_arc          = true
  s.framework             = 'Photos'
  s.default_subspec       = 'Core'

  s.subspec 'Core' do |core|
    core.source_files = 'Desman/Core/**/*.swift'
  end

  s.subspec 'Interface' do |interface|
    interface.dependency     'Desman/Core'
    interface.source_files = 'Desman/Interface/**/*.swift'
    interface.resources    = [ 'Desman/Interface/Assets/**/*.xcassets', 'Desman/Interface/Assets/*.storyboard' ]
  end

  s.subspec 'Debatable' do |debatable|
    debatable.dependency     'Desman/Core'
    debatable.source_files = 'Desman/Debatable/**/*.swift'
  end

  s.subspec 'Remote' do |remote|
    remote.dependency      'Desman/Interface'
    remote.source_files  = 'Desman/Remote/**/*.swift'
    remote.resources     = [ 'Desman/Remote/Assets/**/*.xcassets', 'Desman/Remote/Assets/*.storyboard' ]
    remote.xcconfig      = { 'OTHER_CFLAGS' => '$(inherited) -DDESMAN_INCLUDES_REMOTE' }
  end

  s.subspec 'Realtime' do |realtime|
    realtime.dependency 'Desman/Remote'
    realtime.dependency 'SwiftWebSocket', '~> 2.3.0'
    realtime.xcconfig   = { 'OTHER_CFLAGS' => '$(inherited) -DDESMAN_INCLUDES_REALTIME' }
  end
end
