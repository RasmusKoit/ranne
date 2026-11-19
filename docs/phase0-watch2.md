# Phase 0: does the OnePlus Watch 2 work with the bridge?

One evening of testing that decides whether the rest of the plan starts. Run it on
the unmodified app (plus the Ranne rename), a OnePlus Watch 2 and an iPhone.

Follow `docs/setup.md` for the build and install commands. This page adds what to
record and what counts as a pass.

## Before you start

- [ ] The watch is already activated (it has been paired once with an Android phone
      through OHealth). Turn Bluetooth **off** on that Android phone for the whole test.
- [ ] The watch is in **Smart Mode**, not Power Saver. Power Saver turns off the
      Wear OS chip and no third-party app runs.
- [ ] On the Mac: Android Studio, full Xcode, `brew install xcodegen`.
- [ ] On the watch: Developer options and Wireless debugging are on, and `adb connect`
      works.
- [ ] Any earlier pairing between this watch and this iPhone is removed on **both**
      sides (iPhone: Settings > Bluetooth > (i) > Forget This Device; watch: Bluetooth
      settings > unpair). Remove other bridge apps from the watch.

## Record the setup

Fill this in first. It goes into `docs/phase0-results.md`.

| Item | Value |
| --- | --- |
| Watch model and colour variant | |
| Wear OS version (Settings > About) | |
| Watch build number | |
| Watch mode during the test | Smart / Power Saver |
| iPhone model | |
| iOS version | |
| Apple signing | free Personal Team / paid |
| Commit tested (`git rev-parse --short HEAD`) | |
| Date | |

## Steps

Each step has one pass condition. If a step fails, run
`scripts/collect-logs.sh -n "<step number> failed"` before trying anything else, then
note what you saw. Stop at the first failure in steps 1 to 5: later steps depend on them.

| # | Step | Pass when |
| --- | --- | --- |
| 1 | Build and install the watch app (`./gradlew :app:installDebug`) | The app opens on the watch |
| 2 | Open the watch app. Grant notification access and the battery-optimisation exemption when asked | `collect-logs.sh` reports `battery_optimisation_exempt=yes` in `session.txt` |
| 3 | Build and install the iPhone app from Xcode. Allow Bluetooth and Health access | The app opens and shows it is waiting for a watch |
| 4 | Start the connection in the watch app | The watch finds the iPhone within 30 seconds |
| 5 | Accept the pairing prompts on both devices | iPhone Settings > Bluetooth lists the watch as connected, and its (i) page shows **Share System Notifications** switched on |
| 6 | Send yourself an iMessage or email from another device | It appears on the watch within about 5 seconds. Note the delay |
| 7 | Dismiss that notification on the watch | It disappears from the iPhone's Notification Centre |
| 8 | Wear the watch for 15 minutes, then open the Health app on the iPhone | Heart rate samples from the watch are listed under Browse > Heart > Heart Rate > Show All Data |
| 9 | Walk out of Bluetooth range for 5 minutes and come back | The link is restored without touching either app, and a new notification arrives |
| 10 | Restart the iPhone and unlock it once | The link is restored within about 60 seconds without opening the app |
| 11 | Leave both devices alone overnight, watch on the charger or wrist | In the morning a new notification still arrives on the watch |
| 12 | Note the watch battery level at the start and end of step 11 | Recorded. No pass condition yet; this is the first battery data point |

After step 11, run `scripts/collect-logs.sh -n "overnight"` once more, whatever the
outcome.

## Things to watch for

These are the known ways this goes wrong. Note any that happen.

- **No pairing prompt on the iPhone.** Try pairing from the watch's own Bluetooth
  settings, then return to the app.
- **Connected in Bluetooth settings, but nothing arrives.** Check the **Share System
  Notifications** switch from step 5. If the switch is missing, ANCS was never
  authorised.
- **Works, then goes silent after a while.** Likely the battery-optimisation
  exemption. Recheck step 2.
- **Subscribes fail after reinstalling an app.** Stale bond. Forget the pairing on
  both devices and pair again; a Bluetooth toggle does not clear it.
- **The app cannot associate with the iPhone at all.** Some firmware blocks the
  normal association. Capture logs; this decides whether task B7 is needed.

## What to hand back

1. The filled-in setup table.
2. Pass or fail for each step, with the measured delay for step 6.
3. Every zip written by `scripts/collect-logs.sh`.
4. Xcode's console output for the iPhone app if step 4, 5 or 8 failed.

A pass on steps 1 to 8 means the Watch 2 can do the job and the build plan continues.
Failures in 9 to 11 are reliability work for Track B, not a stop.
