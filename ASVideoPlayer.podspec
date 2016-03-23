#
# Be sure to run `pod lib lint ASVideoPlayer.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "ASVideoPlayer"
  s.version          = "0.9.0"
  s.summary          = "ASVideoPlayer simplifies the process of playing a video."

  s.description      = <<-DESC
Playing a video appears to be not so simple. ASVideoPlayer is built on AVPlayer and uses Key-Value Observing(KVO) to handle video events.
                       DESC

  s.homepage         = "https://github.com/Asbat/ASVideoPlayer"
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'MIT'
  s.author           = { "Alexey Stoyanov" => "astoyanov.dev@gmail.com" }
  s.source           = { :git => "https://github.com/Asbat/ASVideoPlayer.git", :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.platform     = :ios, '7.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes/**/*'
  s.resource_bundles = {
    'ASVideoPlayer' => ['Pod/Assets/VideoPlayer/*']
  }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  s.frameworks = 'UIKit', 'AVFoundation'
  # s.dependency 'AFNetworking', '~> 2.3'
end
