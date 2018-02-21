# QiscusRTC

Qiscus RTC SDK is a product that makes adding voice calling to mobile apps easy. It handles all the complexity of signaling and audio management while providing you the freedom to create a stunning user interface.
We highly recommend that you implement a better push notification for increasing call realiability, for example APNs, Pushkit, MQTT, or other standard messaging protocol.

Callkit support

## Quick Start

Below is a step-by-step guide on setting up the Qiscus RTC SDK for the first time

### Dependency

Add to your project podfile

```
pod 'QiscusRTC'
```

```swift
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

```swift
    QiscusRTC.setup(appId: [Your_AppID], appSecret: [Your_Secret_Key])
```
To get your `app_id` and `app_secret`, please [contact us](https://www.qiscus.com/contactus).

### Init with custom host

Qiscus also provides on-premise package, so you can host signaling server on your own network. Please [contact us](https://www.qiscus.com/contactus) to get further information.

Parameters:
* app_id: String
* app_secret: String
* host: String

```swift
    QiscusRTC.setup(appId: [Your_AppID], appSecret: [Your_Secret_Key], host: [Your_server])
```

## Method

### Register User

Before user can start call each other, they must register the user to our server

Parameters:
* username: String
* displayName: String

```swift
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


```swift
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

```swift
QiscusRTC.incomingCall(roomId: "receive_room_id", isVideo: false/true, calleerUsername: "juang@qiscus.co", calleerDisplayName: "juang", calleerDisplayAvatar: URL(string: "http://...") { (target, error) in
    if error == nil {
        self.present(target, animated: true, completion: nil)
    }
}
```

### Example

