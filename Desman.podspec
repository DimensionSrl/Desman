Pod::Spec.new do |s|
  s.name                  = 'Desman'
  s.version               = '0.1.4'
  s.summary               = 'An event tracking tool for mobile apps.'
  s.homepage              = 'http://desman.dimension.it'
  s.license               = 'MIT'
  s.authors               = [ 'Matteo Gavagnin' => 'm@macteo.it', 'Dimension S.r.l.' => 'info@dimension.it' ]
  s.social_media_url      = 'http://twitter.com/macteo'
  s.ios.deployment_target = '8.0'
  s.source                = { :git => 'http://10.10.1.4/ios/desman.git', :tag => "v#{s.version}" }
  s.requires_arc          = true
  s.default_subspec       = 'Core'

  s.subspec 'Core' do |core|
    core.framework        = 'Photos'
    core.source_files     = 'Desman/Core/**/*.swift'

    core.subspec 'Interface' do |interface|
      interface.source_files  = 'Desman/Interface/**/*.swift'
      interface.resources     = [ 'Desman/Interface/Assets/**/*.xcassets', 'Desman/Interface/Assets/*.storyboard' ]
    end

    core.subspec 'Debatable' do |debatable|
      debatable.source_files = 'Desman/Debatable/**/*.swift'
    end

    core.subspec 'Remote' do |remote|
      remote.source_files = 'Desman/Remote/**/*.swift'
      remote.subspec 'Realtime' do |realtime|
        realtime.xcconfig = { 'OTHER_CFLAGS' => '$(inherited) -DDESMAN_INCLUDES_REALTIME' }
        realtime.dependency "SwiftWebSocket", "~> 2.3.0"
      end
    end
  end
end
