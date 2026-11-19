# Entitlement probe

A throwaway app that answers one question for checkpoint H2: **can your Apple developer
team sign and install an app that uses Apple's Accessory Notifications route?**

That route needs three app extensions, each with its own entitlement:

| Extension | Extension point | Entitlement |
| --- | --- | --- |
| Data provider | `com.apple.accessory-data-provider` | `com.apple.developer.accessory-data-provider` |
| Transport security | `com.apple.accessory-transport-security` | `com.apple.developer.accessory-transport-security` |
| Transport | `com.apple.accessory-transport-extension` | `com.apple.developer.accessory-transport-extension` |

Apple's documentation says each extension must have its entitlement but does not say
whether a team can simply switch them on. This project finds out. It forwards no
notifications and talks to no watch.

## Run it

Needs a Mac with Xcode (iOS 26.5 SDK or later) and `brew install xcodegen`.

```sh
cd apps/ios-probe
xcodegen generate
open RanneProbe.xcodeproj
```

In Xcode, select your team for all four targets (RanneProbe and the three Probe
extensions), pick your iPhone as the destination, and press Run.

## Read the result

| What happens | Meaning |
| --- | --- |
| The app installs and shows "Ranne entitlement probe" | The entitlements are available to your team. The official route is open |
| Signing fails with a message that the provisioning profile does not include one of the three entitlements | The entitlements need a paid account or Apple's approval. Note the exact message and whether the team was a free Personal Team |
| The project does not compile | The scaffold is wrong, not your account. See below |

Then try once more with the other kind of team if you have one (free Personal Team
versus paid Apple Developer Program), and record both outcomes in
`docs/phase0-results.md`. Delete the app from the iPhone afterwards.

## Known limits of this scaffold

It is compiled in CI (unsigned, against the newest Xcode on the `macos-26` runner) but has
**never been signed or run on a device**:

- The entitlement values are written as booleans. If Xcode's capability editor writes
  something else, trust Xcode.
- Apple's notification guide and its `AccessoryTransportAppExtension` reference name the
  transport handler's methods differently. The SDK wants `messageReceived(_:completion:)`
  and `sessionInvalidated(error:)`; `dataEventHandler(event:)` is deprecated.

Compile errors do not answer the H2 question. A signing or provisioning error does.

Sources: [Receiving iOS notifications on an accessory](https://developer.apple.com/documentation/accessorytransportextension/receiving-ios-notifications-on-an-accessory),
[AccessoryTransportAppExtension](https://developer.apple.com/documentation/accessorytransportextension/accessorytransportappextension).
