# CRED-STACKVIEW

## Usage
`StackCard` behaves a lot like a standard `UICollectionView`. 
To use it inside your `UIViewController`:

```swift
class ExampleViewController: UIViewController, StackCardDatasource {
    
    private var cardSwiper: StackCard!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        cardSwiper = StackCard(frame: self.view.bounds)
        view.addSubview(cardSwiper)
        
        cardSwiper.datasource = self
        
        // register cardcell for storyboard use
        cardSwiper.register(nib: UINib(nibName: "ExampleCell", bundle: nil), forCellWithReuseIdentifier: "ExampleCell")
    }
    
    func cardForItemAt(stackCardView: StackCardView, cardForItemAt index: Int) -> CardCell {
        
        if let cardCell = stackCardView.dequeueReusableCell(withReuseIdentifier: "ExampleCell", for: index) as? ExampleCardCell {
            return cardCell
        }
        return CardCell()
    }
    
    func numberOfCards(stackCardView: StackCardView) -> Int {
        return 100
    }
}
```

#### Properties
```swift
/// Indicates if side swiping on cards is enabled. Set to false if you don't want side swiping. Default is `true`.
@IBInspectable public var isSideSwipingEnabled: Bool = true
/// Allows you to enable/disable the stacking effect. Default is `true` (enabled).
@IBInspectable public var isStackingEnabled: Bool = true
/// The transform animation that is shown on the top card when scrolling through the cards. Default is 0.05.
@IBInspectable public var firstItemTransform: CGFloat = 0.05
/// The inset (spacing) at the top for the cards. Default is 160.
@IBInspectable public var topInset: CGFloat = 160
/// The inset (spacing) at each side of the cards. Default is 0.
@IBInspectable public var sideInset: CGFloat = 0
/// Sets how much of the next card should be visible. Default is 0.
@IBInspectable public var visibleNextCardHeight: CGFloat = 0
/// Vertical spacing between the focussed card and the bottom (next) card. Default is 0.
@IBInspectable public var cardSpacing: CGFloat = 0
/// Allows you to set the view to Stack at the Top or at the Bottom. Default is true.
@IBInspectable public var isStackOnBottom: Bool = true
/// Sets how many cards of the stack are visible in the background
@IBInspectable public var stackedCardsCount: Int = 1
/** 
 Returns an array of indexes (as Int) that are currently visible in the `StackCardView`.
 This includes cards that are stacked (behind the focussed card).
*/
public var indexesForVisibleCards: [Int]
```

#### Other
##### Just like with a regular `UICollectionView`, you can reload the data by calling
```swift
cardSwiper.reloadData()
```

##### Get the current focussed card index
```swift
cardSwiper.focussedCardIndex
```

##### Scroll to a specifc card by calling
```swift
cardSwiper.scrollToCard(at: Int, animated: Bool) -> Bool
```

##### Get a card at a specified index
```swift
cardSwiper.cardForItem(at: Int) -> CardCell?
```

##### Swipe a card away programatically
```swift
cardSwiper.swipeCardAwayProgrammatically(at: Int, to: SwipeDirection, withDuration: TimeInterval = 0.3) -> Bool
```

##### Moving/Deleting/Inserting cards at runtime
Make sure to update your datasource first, otherwise an error will occur.
```swift
cardSwiper.moveCard(at: Int, to: Int)
cardSwiper.deleteCards(at: [Int])
cardSwiper.insertCards(at: [Int])
```

### Delegation
To handle swipe gestures, implement the `StackCardDelegate`.

```swift
class ViewController: UIViewController, StackCardDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()

        cardSwiper.delegate = self
    }
    
    func willSwipeCardAway(card: CardCell, index: Int, swipeDirection: SwipeDirection) {
    
        // called right before the card animates off the screen (optional).
    }

    func didSwipeCardAway(card: CardCell, index: Int, swipeDirection: SwipeDirection) {

        // handle swipe gestures (optional).
    }
    
    func didCancelSwipe(card: CardCell, index: Int) {
        
        // Called when a card swipe is cancelled (when the threshold wasn't reached)
    }
    
    func sizeForItem(stackCardView: StackCardView, index: Int) -> CGSize {
    
        // Allows you to return custom card sizes (optional).
        return CGSize(width: stackCardView.frame.width * 0.75, height: stackCardView.frame.height * 0.75)
    }
    
    func didScroll(stackCardView: StackCardView) {
    
        // Tells the delegate when the user scrolls through the cards (optional).
    }
    
    func didEndScroll(stackCardView: StackCardView) {
    
        // Tells the delegate when scrolling through the cards came to an end (optional).
    }
    
    func didDragCard(card: CardCell, index: Int, swipeDirection: SwipeDirection) {
    
        // Called when the user starts dragging a card to the side (optional).
    }
    
    func didTapCard(stackCardView: StackCardView, index: Int) {
    
        // Tells the delegate when the user taps a card (optional).
    }
    
    func didHoldCard(stackCardView: StackCardView, index: Int, state: UIGestureRecognizer.State) {
    
        // Tells the delegate when the user holds a card (optional).
    }
}
```

### Customization
Subclass the `CardCell` to customize the cards.
```swift
class ExampleCardCell: CardCell {

}
```

## Key Features
- [x] Option to disable side swiping
- [x] Set custom number of stacked cards
- [x] Code documentation in README.md file
