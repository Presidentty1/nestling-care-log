import Foundation
import LocalAuthentication

class AuthenticationManager {
    static let shared = AuthenticationManager()
    
    private init() {}
    
    func authenticate(reason: String = "Authenticate to access Nestling") async -> Bool {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            // Fallback to passcode if biometrics unavailable
            return await authenticateWithPasscode(reason: reason)
        }
        
        do {
            return try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason)
        } catch {
            logger.debug("Authentication failed: \(error.localizedDescription)")
            return false
        }
    }
    
    private func authenticateWithPasscode(reason: String) async -> Bool {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            return false
        }
        
        do {
            return try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
        } catch {
            return false
        }
    }
    
    func isBiometricsAvailable() -> Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }
}

