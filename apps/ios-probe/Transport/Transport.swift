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
    func messageReceived(_ message: TransportMessage,
                         completion: @escaping @Sendable (AccessoryMessage.Result) -> Void) {
        // No accessory to talk to in the probe.
        completion(.failure(.transportUnavailable))
    }

    func sessionInvalidated(error: AccessoryTransportSession.Error?) {}
}
