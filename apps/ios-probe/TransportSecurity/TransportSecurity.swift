import AccessoryTransportExtension
import ExtensionFoundation

// Empty implementation after Apple's "Receiving iOS notifications on an accessory".

@main
struct TransportSecurity: AccessoryTransportSecurity {
    @AppExtensionPoint.Bind
    static var boundExtensionPoint: AppExtensionPoint {
        Identifier("com.apple.accessory-transport-security")
    }

    func accept(sessionRequest: AccessorySecuritySession.Request) -> AccessorySecuritySession.Request.Decision {
        return sessionRequest.accept {
            SecurityEventHandler()
        }
    }
}

final class SecurityEventHandler: AccessorySecuritySession.EventHandler {
    func messageReceived(_ message: SecurityMessage,
                         completion: @escaping @Sendable (AccessoryMessage.Result) -> Void) {
        // No accessory to talk to in the probe.
        completion(.failure(.transportFailed))
    }

    func sessionInvalidated(error: (any Error)?) {}
}
