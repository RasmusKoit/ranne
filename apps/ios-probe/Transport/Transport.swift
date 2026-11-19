import AccessoryTransportExtension
import ExtensionFoundation

// Empty implementation after Apple's AccessoryTransportAppExtension reference.

@main
struct TransportExtension: AccessoryTransportAppExtension {
    func accept(sessionRequest: AccessoryTransportSession.Request) -> AccessoryTransportSession.Request.Decision {
        return sessionRequest.accept {
            TransportEventHandler()
        }
    }
}

final class TransportEventHandler: AccessoryTransportSession.EventHandler {
    func dataEventHandler(event: AccessoryTransportSession.DataEvent) {
        // No accessory to talk to in the probe; drop the data.
    }

    func invalidationHandler(error: AccessoryTransportSession.Error?) {}
}
