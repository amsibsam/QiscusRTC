Pod::Spec.new do |s|

s.name         = 'QiscusRTC'
s.version      = '0.1.7'
s.summary      = 'Qiscus RTC is call mudule base on WebRTC.'
s.homepage     = 'https://qiscus.com'
s.screenshots  = 'https://raw.githubusercontent.com/qiscus/QiscusRTC/master/Image/callkit.png', 'https://raw.githubusercontent.com/qiscus/QiscusRTC/master/Image/videocall.png'
s.license      = { :type => 'BSD'}
s.author       = { 'juang@qiscus.co' => 'juang@qiscus.co' }
s.platform     = :ios, '10.0'
s.source       = { :git => 'https://github.com/qiscus/QiscusRTC.git', :tag => s.version.to_s }
s.source_files  = 'QiscusRTC', 'QiscusRTC/**/*.{h,m,swift,xib}'
s.resources = 'QiscusRTC/**/*.xcassets'
s.resource_bundles = {
    'QiscusRTC' => ['QiscusRTC/**/*.{lproj,xib,xcassets,imageset,png,mp3}']
}
s.framework    = 'UIKit', 'AVFoundation', 'CoreMotion', 'CoreTelephony', 'AudioToolbox', 'VideoToolbox', 'Systemconfiguration', 'CoreMedia'
s.requires_arc = false
s.libraries    = 'c++', 'z'
s.requires_arc = true
#s.swift_version = '4.0'
s.pod_target_xcconfig = { 'ENABLE_BITCODE' => 'NO' }
s.dependency 'Alamofire'
s.dependency 'WebRTC', '63.11.20455'
s.dependency 'Starscream'
s.dependency 'AlamofireImage'
s.dependency 'SwiftyJSON'
end
