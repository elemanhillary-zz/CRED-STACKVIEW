import Foundation

/// The direction of the `UIPanGesture`.
public enum PanDirection: Int {
    case Up
    case Down
    case Left
    case Right
    case None

    /// Returns true is the PanDirection is horizontal.
    public var isX: Bool { return self == .Left || self == .Right }
    /// Returns true if the PanDirection is vertical.
    public var isY: Bool { return self == .Up || self == .Down }
}
