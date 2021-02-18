import Foundation

/// This delegate is used for delegating `CardCell` actions.
internal protocol CardDelegate: class {

    /**
     Called right before a CardCell is swiped away.
     - parameter cell: The CardCell that is being swiped away.
     - parameter swipeDirection: The direction the card is swiped in. This can be Left, Right or None.
     */
    func willSwipeAway(cell: CardCell, swipeDirection: SwipeDirection)

    /**
     Called when a CardCell is swiped away.
     - parameter cell: The CardCell that is being swiped away.
     - parameter swipeDirection: The direction the card is swiped in. This can be Left, Right or None.
     */
    func didSwipeAway(cell: CardCell, swipeDirection: SwipeDirection)

    /**
     Called when a swipe is aborted because the minimum threshold wasn't reached.
     - parameter cell: The CardCell that was swiped.
    */
    func didCancelSwipe(cell: CardCell)

    /**
     Called while the user is dragging a card to a side.
     
     You can use this to add some custom features to a card when it enters a certain `swipeDirection` (like overlays).
     - parameter card: The CardCell that the user is currently dragging.
     - parameter swipeDirection: The direction in which the card is being dragged.
     */
    func didDragCard(cell: CardCell, swipeDirection: SwipeDirection)
}
