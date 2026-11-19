# Link topology: who connects to whom

*Status: proposed. Needs the owner's review, and the hardware checks at the end before
anything after the transport protocol spec is built.*

## The question

Ranne will have two ways to get iPhone notifications onto the watch:

- **ANCS mode** (works everywhere, what the app does today).
- **Accessory mode** (Apple's Accessory Notifications framework, EU only, adds replies).

They want opposite Bluetooth roles. This document decides how the two modes share, or
do not share, a Bluetooth link.

## How the link works today (ANCS mode)

| | iPhone | Watch |
| --- | --- | --- |
| Link role | Peripheral: the app advertises the companion service (`PeripheralManager.swift`) | Central: scans, connects, bonds (`BleConnectionManager.kt`) |
| ANCS | GATT server, built into iOS | GATT client |
| Companion service `A0E3D5B1-…` (health, call state, quick reply) | GATT server, hosted by the app | GATT client |

The watch initiates everything. The iPhone app only has to keep advertising and keep
its `CBPeripheralManager` alive through state restoration.

## What accessory mode requires

From Apple's documentation, not from testing:

- The companion app registers the watch through AccessorySetupKit, which discovers an
  **advertising** accessory and shows a system picker.
- The transport extension talks to the accessory with a **`CBCentralManager`**. Apple's
  background-support section tells the extension to add the `bluetooth-central`
  background mode and to create its central manager with the session's
  `transportStateRestoreIdentifier`.
- The system relaunches or resumes the suspended extension "when your accessory sends
  an update for a characteristic to which your extension subscribes". So watch-to-phone
  traffic must be GATT notifications from a GATT server **on the watch**.
- Payloads are encrypted end to end with HPKE at the application layer.

Source: [AccessoryTransportAppExtension](https://developer.apple.com/documentation/accessorytransportextension/accessorytransportappextension),
[Receiving iOS notifications on an accessory](https://developer.apple.com/documentation/accessorytransportextension/receiving-ios-notifications-on-an-accessory).

So in accessory mode the iPhone is the central and GATT client, and the watch is the
peripheral and GATT server: the reverse of today.

## Options

### A. One link, iPhone as central (recommended for accessory mode)

The watch advertises a Ranne transport service and runs a GATT server. The iPhone
connects. On that same link:

- **Transport**: the iPhone's transport extension writes to, and subscribes on, the
  watch's GATT server.
- **AMS (media)** and, if still wanted, **ANCS**: the watch acts as GATT *client* of
  the services iOS exposes. GATT client and server roles are independent of who
  initiated the link; this is how ordinary ANCS accessories work, since they are
  peripherals that read ANCS from the phone.
- **Health sync**: see "Health sync in accessory mode" below.

For: one link, the roles Apple designed for, and wake-up of the iPhone side handled by
the system instead of by our app's state restoration.

Against: the watch must advertise whenever it is disconnected, the existing 742-line
connection manager assumes the opposite direction, and three behaviours are unproven
on this hardware (see checks 1, 3 and 4).

### B. Two links, one in each direction

Keep today's watch-initiated link for ANCS and the companion service, and add a second,
iPhone-initiated link for the transport.

Rejected. Two simultaneous LE connections between the same pair of devices are not
something either platform supports reliably, and it doubles the radio and reconnect
work for no benefit over A.

### C. Keep the watch as central and reuse that link for the transport

The watch keeps scanning and connecting. The transport extension would act as GATT
client over a link the watch initiated.

Not recommended. It is unclear whether AccessorySetupKit can register an accessory
that never advertises, and whether a `CBCentralManager` in an extension can address a
device that connected to the phone as a central. Both would have to hold, and Apple's
guide assumes neither. Keep as a fallback to investigate only if A fails check 1.

## Decision

1. **ANCS mode stays exactly as it is.** It is the phase 0 and phase 1 path and the
   path for users outside the EU. No role changes there.
2. **Accessory mode uses option A.** The watch advertises and serves; the iPhone
   connects.
3. **The two modes are exclusive at runtime.** The watch app runs one connection
   strategy at a time, chosen by the route setting (task C13). Switching modes tears
   the link down and starts the other strategy; it never runs both.
4. **The connection code is split by strategy, not patched.** Introduce a small
   interface with two implementations: the existing manager (watch as central) and a
   new one (watch as peripheral). Task B3, which extracts the reconnect policy into a
   pure class, is the first step toward that seam.

## Health sync in accessory mode

The companion service is hosted by the iPhone app. Whether the watch can still reach it
as a GATT client over an iPhone-initiated link is unverified (check 3). Two outcomes:

- **It works**: health sync is unchanged in accessory mode.
- **It does not**: health records move onto the watch's GATT server, with the iPhone
  as client, carried by the framework's background worker. That is the subject of task
  D4 and would also remove the dependency on the iPhone app staying alive.

Either way the record format in `specs/health-ble-protocol.md` does not change; only
the characteristic that carries it does.

## Consequences for other tasks

- **C2 (transport protocol spec)** defines the watch-hosted service: one
  write characteristic (phone to watch) and one notify characteristic (watch to phone),
  with fragmentation. It should reserve room for health records.
- **C6 (watch GATT server and advertising)** implements option A's watch side behind
  the new strategy interface.
- **C7 (AccessorySetupKit pairing)** uses the transport service UUID from C2 as its
  discovery descriptor.
- **C13 (route selection)** owns the mode switch described in decision 3.

## Risks

- **Advertising cost.** A watch that advertises all night while the phone is away
  costs battery. Mitigation: low-power advertising interval, and measure it.
- **OnePlus background limits.** The foreground service and battery-optimisation
  exemption already needed for ANCS mode are needed here too; advertising from the
  background may be throttled differently from scanning.
- **Stale bonds when switching modes.** Changing who initiates may leave pairing state
  that the other mode trips over, as already seen after reinstalls.
- **Entitlements.** All of accessory mode depends on the three Apple entitlements being
  obtainable (checkpoint H2). If they are not, this document's accessory half is void
  and ANCS mode is the product.

## What to check on hardware (checkpoint H4)

1. The Watch 2 can advertise the transport service from a foreground service with the
   screen off, and the iPhone's AccessorySetupKit picker finds it.
2. The iPhone's transport extension connects, subscribes, and a watch-side notification
   relaunches the suspended extension.
3. Over that iPhone-initiated link, the watch can open a GATT client to the phone and
   discover AMS, ANCS and the companion service. Record which of the three are visible.
4. After walking out of range and back, the link is restored without opening either
   app. Record how long it takes.
5. Battery drain overnight with the phone absent, advertising the whole time.
6. Switching from ANCS mode to accessory mode and back works without forgetting the
   pairing by hand.

If check 1 or 2 fails, stop and revisit option C. If only check 3 fails for the
companion service, proceed and move health sync as described above.
