Pod::Spec.new do |s|

s.name         = "QiscusRTC"
s.version      = "0.1.0"
s.summary      = "Qiscus RTC is call mudule base on WebRTC."
s.homepage     = "http://qiscus.com"
# s.screenshots  = "www.example.com/screenshots_1.gif", "www.example.com/screenshots_2.gif"
s.license      = "BSD"
s.author       = { "juang@qiscus.co" => "juang@qiscus.co" }
s.platform     = :ios, "9.0"
s.source       = { :git => 'https://gitlab.devops.mhealth.tech/asharijuang/QiscusRTC.git', :tag => s.version.to_s }
s.source_files  = "QiscusRTC", "QiscusRTC/**/*.{h,m,swift,xib}"
s.resources = "QiscusRTC/**/*.xcassets"
s.resource_bundles = {
    'QiscusRTC' => ['QiscusRTC/**/*.{lproj,xib,xcassets,imageset,png,mp3}']
}
s.framework    = 'UIKit', 'AVFoundation', 'CoreMotion', 'CoreTelephony', 'AudioToolbox', 'VideoToolbox', 'Systemconfiguration', 'CoreMedia'
s.requires_arc = false
s.libraries    = "c++", "z"
s.requires_arc = true

s.pod_target_xcconfig = { 'ENABLE_BITCODE' => 'NO' }
s.dependency "Alamofire"
s.dependency "WebRTC"
s.dependency "Starscream"
s.dependency "AlamofireImage"
end
