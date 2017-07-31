
Pod::Spec.new do |s|
  s.name             = 'AFTPhotoScroller'
  s.version          = '0.1.8'
  s.summary          = 'A simple photo scrolling view using like iOS photo app.'

  s.description      = <<-DESC
This photo scrolling view can provide features such as:
1. Controller free.
2. Both horizontal and vertical page scrolling.
3. Parallax Scrolling Support.
                       DESC

  s.homepage         = 'https://github.com/huang-kun/AFTPhotoScroller'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'huangkun' => 'jack-huang-developer@foxmail.com' }
  s.source           = { :git => 'https://github.com/huang-kun/AFTPhotoScroller.git', :tag => s.version.to_s }
  s.social_media_url = 'https://weibo.com/u/5736413097'

  s.ios.deployment_target = '6.0'

  s.source_files = 'AFTPhotoScroller/Classes/**/*'
  
  # s.resource_bundles = {
  #   'AFTPhotoScroller' => ['AFTPhotoScroller/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit'
end
