import AccessoryNotifications
import AccessoryTransportExtension
import ExtensionFoundation

// Empty implementation after Apple's "Receiving iOS notifications on an accessory".
// The probe only needs this target to compile, sign and embed.

@main
struct DataProvider: AccessoryDataProvider {
    var extensionPoint: AppExtensionPoint {
        Identifier("com.apple.accessory-data-provider")
        Implementing {
            NotificationsForwarding {
                NotificationHandler()
            }
        }
    }
}

final class NotificationHandler: NotificationsForwarding.AccessoryNotificationsHandler {
    var session: NotificationsForwarding.Session?

    func didActivate(for session: NotificationsForwarding.Session) {
        self.session = session
    }

    func addNotification(_ notification: AccessoryNotification,
                         alertingContext: AlertingContext) async throws -> Bool {
        // The probe forwards nothing, so the accessory never alerts.
        return false
    }

    func updateNotification(_ notification: AccessoryNotification) {}

    func removeNotification(identifier: AccessoryNotification.Identifier) {}

    func removeAllNotifications() {}

    func messageHandler(_ message: TransportMessage) {}

    func didInvalidate() {
        session = nil
    }
}
