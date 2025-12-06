import SwiftUI

/// Helper for applying SF Symbol effects with Reduce Motion support
struct SymbolEffects {
    static var reduceMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }
    
    /// Apply pulse effect to an Image if Reduce Motion is disabled
    static func pulse<T: View>(_ view: T, value: AnyHashable? = nil) -> some View {
        if reduceMotion {
            return AnyView(view)
        } else {
            if let value = value {
                return AnyView(view.symbolEffect(.pulse, options: .nonRepeating, value: value))
            } else {
                return AnyView(view.symbolEffect(.pulse, options: .nonRepeating))
            }
        }
    }
    
    /// Apply bounce effect to an Image if Reduce Motion is disabled
    static func bounce<T: View>(_ view: T, value: AnyHashable? = nil) -> some View {
        if reduceMotion {
            return AnyView(view)
        } else {
            if let value = value {
                return AnyView(view.symbolEffect(.bounce, value: value))
            } else {
                return AnyView(view.symbolEffect(.bounce))
            }
        }
    }
}

extension View {
    /// Apply pulse effect to SF Symbol images, respecting Reduce Motion
    func symbolPulse(value: AnyHashable? = nil) -> some View {
        if UIAccessibility.isReduceMotionEnabled {
            return AnyView(self)
        } else {
            if let value = value {
                return AnyView(self.symbolEffect(.pulse, options: .nonRepeating, value: value))
            } else {
                return AnyView(self.symbolEffect(.pulse, options: .nonRepeating))
            }
        }
    }
    
    /// Apply bounce effect to SF Symbol images, respecting Reduce Motion
    func symbolBounce(value: AnyHashable? = nil) -> some View {
        if UIAccessibility.isReduceMotionEnabled {
            return AnyView(self)
        } else {
            if let value = value {
                return AnyView(self.symbolEffect(.bounce, value: value))
            } else {
                return AnyView(self.symbolEffect(.bounce))
            }
        }
    }
}

