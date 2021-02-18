import Foundation
import UIKit

internal extension UIPanGestureRecognizer {

    /**
     This calculated var stores the direction of the gesture received by the `UIPanGestureRecognizer`.
     */
    var direction: PanDirection? {
        let velocity = self.velocity(in: view)
        let vertical = abs(velocity.y) > abs(velocity.x)
        switch (vertical, velocity.x, velocity.y) {
        case (true, _, let y) where y < 0: return .Up
        case (true, _, let y) where y > 0: return .Down
        case (false, let x, _) where x > 0: return .Right
        case (false, let x, _) where x < 0: return .Left
        default: return .None
        }
    }
}

extension VerticalCardSwiper {
    /// Takes an index as Int and converts it to an IndexPath with row: index and section: 0.
    internal func convertIndexToIndexPath(for index: Int) -> IndexPath {
        return IndexPath(row: index, section: 0)
    }
}
