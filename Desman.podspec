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
  s.xcconfig              = { 'OTHER_SWIFT_FLAGS' => '$(inherited) -DDESMAN_AS_COCOAPOD' }

  s.subspec 'Core' do |core|
    core.source_files  = 'Desman/Core/**/*.swift'
    core.exclude_files = 'Desman/Core/Vendor/*'
    core.module_name   = 'Desman'
  end

  s.subspec 'Interface' do |interface|
    interface.dependency      'Desman/Core'
    interface.exclude_files = 'Desman/Core/Vendor/*'
    interface.source_files  = 'Desman/Interface/**/*.swift'
    interface.resources     = [ 'Desman/Interface/Assets/**/*.xcassets', 'Desman/Interface/Assets/*.storyboard' ]
    interface.module_name   = 'DesmanInterface'
  end

  s.subspec 'Debatable' do |debatable|
    debatable.dependency     'Desman/Core'
    debatable.source_files = 'Desman/Debatable/**/*.swift'
    debatable.module_name  = 'Desman'
  end

  s.subspec 'Crash' do |crash|
    crash.source_files       = 'Desman/Crash/**/*.swift'
    crash.vendored_framework = 'Desman/Crash/Vendor/CrashReporter.framework'
    crash.resource           = 'Desman/Crash/Vendor/CrashReporter.framework'
    crash.xcconfig           = { 'OTHER_SWIFT_FLAGS' => '$(inherited) -DDESMAN_INCLUDES_CRASH_REPORTER', 'LD_RUNPATH_SEARCH_PATHS' => '@loader_path/../Frameworks' }
    crash.module_name        = 'Desman'
  end

  s.subspec 'Remote' do |remote|
    remote.dependency      'Desman/Interface'
    remote.source_files  = 'Desman/Remote/**/*.swift'
    remote.resources     = [ 'Desman/Remote/Assets/**/*.xcassets', 'Desman/Remote/Assets/*.storyboard' ]
    remote.xcconfig      = { 'OTHER_SWIFT_FLAGS' => '$(inherited) -DDESMAN_INCLUDES_REMOTE' }
    remote.module_name   = 'DesmanRemote'
  end

  s.subspec 'Realtime' do |realtime|
    realtime.dependency  'Desman/Remote'
    realtime.dependency  'SwiftWebSocket', '~> 2.3.0'
    realtime.xcconfig    = { 'OTHER_SWIFT_FLAGS' => '$(inherited) -DDESMAN_INCLUDES_REALTIME' }
    realtime.module_name = 'DesmanRemote'
  end
end
