Pod::Spec.new do |s|
  s.name                  = 'Desman'
  s.version               = '0.2.6'
  s.summary               = 'An event tracking tool for mobile apps.'
  s.homepage              = 'http://desman.dimension.it'
  s.license               = 'MIT'
  s.authors               = [ 'Matteo Gavagnin' => 'matteo.gavagnin@dimension.it', 'Dimension S.r.l.' => 'info@dimension.it' ]
  s.social_media_url      = 'http://twitter.com/macteo'
  s.ios.deployment_target = '8.0'
  s.source                = { :git => 'http://10.10.1.4/ios/desman.git', :tag => "v#{s.version}"}
  s.requires_arc          = true
  s.frameworks            = [ 'Photos', 'CoreData' ]
  s.default_subspec       = 'Core'
  s.xcconfig              = { 'OTHER_SWIFT_FLAGS' => '$(inherited) -DDESMAN_AS_COCOAPOD' }

  s.subspec 'Core' do |core|
    core.source_files  = 'Desman/Core/**/*.swift'
    core.resources     = [ 'Desman/Core/Assets/**/*.xcassets', 'Desman/Core/Assets/*.storyboard', 'Desman/Core/Resources/**']
  end

  s.subspec 'Debatable' do |debatable|
    debatable.dependency     'Desman/Core'
    debatable.source_files = 'Desman/Debatable/**/*.swift'
  end

  s.subspec 'Remote' do |remote|
    remote.dependency      'Desman/Core'
    remote.dependency      'SwiftWebSocket', '~> 2.3.0'
    remote.source_files  = 'Desman/Remote/**/*.swift'
    remote.resources     = [ 'Desman/Remote/Assets/**/*.xcassets', 'Desman/Remote/Assets/*.storyboard' ]
  end
end
