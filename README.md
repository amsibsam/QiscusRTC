# QiscusRTC

[![Platform](https://img.shields.io/cocoapods/p/QiscusRTC.svg?style=flat)](http://cocoapods.org/pods/QiscusRTC)
![Language](https://img.shields.io/badge/language-Swift%203.2-orange.svg)
[![CocoaPods](https://img.shields.io/cocoapods/v/QiscusRTC.svg?style=flat)](http://cocoapods.org/pods/QiscusRTC)


Qiscus RTC SDK is a product that makes adding voice calling to mobile apps easy. It handles all the complexity of signaling and audio management while providing you the freedom to create a stunning user interface.
We highly recommend that you implement a better push notification for increasing call realiability, for example APNs, Pushkit, MQTT, or other standard messaging protocol.

Callkit support

<p><img src="https://d1edrlpyc25xu0.cloudfront.net/kiwari-prod/image/upload/QG2MphljcI/callkit.png" width="30%" /></p>

## Quick Start

Below is a step-by-step guide on setting up the Qiscus RTC SDK for the first time

### Dependency

Add to your project podfile

```
platform :ios, '10.0'

pod 'QiscusRTC'
```

```
import QiscusRTC
```
### Permission

Add to your project info.plist
camera and microphone

## Callkit

add this in .plist

```
<key>UIBackgroundModes</key>
<array>
<string>fetch</string>
<string>remote-notification</string>
<string>audio</string>
<string>voip</string>
</array>
```
## Authentication

### Init Qiscus

Init Qiscus at your application

Parameters:
* app_id: String
* app_secret: String

```
QiscusRTC.setup(appId: [Your_AppID], appSecret: [Your_Secret_Key])
```
To get your `app_id` and `app_secret`, please [contact us](https://www.qiscus.com/contactus).

### Init with custom host

Qiscus also provides on-premise package, so you can host signaling server on your own network. Please [contact us](https://www.qiscus.com/contactus) to get further information.

Parameters:
* app_id: String
* app_secret: String
* host: String

```
QiscusRTC.setup(appId: [Your_AppID], appSecret: [Your_Secret_Key], host: [Your_server])
```

## Method

### Register User

Before user can start call each other, they must register the user to our server

Parameters:
* username: String
* displayName: String

```
QiscusRTC.register(username: "juang@qiscus.co", displayName: "juang")
```


### Start Call

Start Call, as callee you can call anyone with username. You can define roomId or leave it and we can generate random room id.

Start call object:
* roomId: String
* calleeUsername: String
* calleeDisplayName: String
* isVideo: Bool
* calleeDisplayAvatar: URL


```
QiscusRTC.startCall(roomId: "unique_room_id", isVideo: true/true, calleeUsername: "e@qiscus.co", calleeDisplayName: "Evan P", calleeDisplayAvatar: URL(string: "http://...") { (target, error) in
    if error == nil {
        self.present(target, animated: true, completion: nil)
    }
}
```
### Incoming Call

When you receive a signal, message or event incoming call. You must set roomID and caller username to autenticate call.

Start call object:
* roomId: String
* calleerUsername: String
* calleerDisplayName: String
* isVideo: Bool
* calleerDisplayAvatar: URL

```
QiscusRTC.incomingCall(roomId: "receive_room_id", isVideo: false/true, calleerUsername: "juang@qiscus.co", calleerDisplayName: "juang", calleerDisplayAvatar: URL(string: "http://...") { (target, error) in
    if error == nil {
        self.present(target, animated: true, completion: nil)
    }
}
```

### Continue Call

when you receive call in background or lock screen, then you open the app you need to redirect view to call screen.

```
if QiscusRTC.isCallActive {
    let target  = currentViewController()
    let callUI  = QiscusRTC.getCallUI()
    target.navigationController?.present(callUI, animated: true, completion: {
        // Your Code
    })
}
```
