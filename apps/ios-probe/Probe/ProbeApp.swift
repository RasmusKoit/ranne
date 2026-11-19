import SwiftUI

/// Host app for the entitlement probe. It does nothing at runtime: if this app
/// installs and launches on an iPhone with its three extensions embedded, the
/// developer team can use the accessory entitlements.
@main
struct ProbeApp: App {
    var body: some Scene {
        WindowGroup {
            VStack(alignment: .leading, spacing: 12) {
                Text("Ranne entitlement probe")
                    .font(.title2.bold())
                Text("If you can read this on an iPhone, Xcode signed and installed the app together with its data provider, transport security and transport extensions.")
                Text("Record the result in docs/phase0-results.md, then delete this app.")
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
    }
}
