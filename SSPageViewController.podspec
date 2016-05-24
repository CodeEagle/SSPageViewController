#
# Be sure to run `pod lib lint SSPageView.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "SSPageViewController"
  s.version          = "0.1.0"
  s.summary          = "SSPageViewController"

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!
  s.description      = <<-DESC
  SSPageView infinite Loop, Swift Generic Type Support
                       DESC

  s.homepage         = "https://github.com/CodeEagle/SSPageViewController"
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'MIT'
  s.author           = { "CodeEagle" => "stasura@hotmail.com" }
  s.source           = { :git => "https://github.com/CodeEagle/SSPageViewController.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/_SelfStudio'

  s.platform     = :ios, '8.0'
  s.requires_arc = true
  s.source_files = 'Source/*'
  s.frameworks = 'UIKit'
  s.dependency 'HMSegmentedControl_CodeEagle'
  s.dependency 'SnapKit'
end
