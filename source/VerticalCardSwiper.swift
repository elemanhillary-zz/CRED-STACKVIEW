import Foundation
import UIKit

/**
 The StackCard is a subclass of `UIView` that has a `StackCardView` embedded.
 
 To use this, you need to implement the `StackCardDatasource`.
 
 If you want to handle actions like cards being swiped away, implement the `StackCardDelegate`.
 */
public class StackCard: UIView {

    /// The collectionView where all the magic happens.
    public var stackCardView: StackCardView!

    /// Indicates if side swiping on cards is enabled. Default is `true`.
    @IBInspectable public var isSideSwipingEnabled: Bool = true {
        willSet {
            if newValue {
                horizontalPangestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
            } else {
                stackCardView.removeGestureRecognizer(horizontalPangestureRecognizer)
            }
        }
    }
    /// The inset (spacing) at the top for the cards. Default is 160.
    @IBInspectable public var topInset: CGFloat = 160 {
        didSet {
            setCardSwiperInsets()
        }
    }
    /// The inset (spacing) at each side of the cards. Default is 0.
    @IBInspectable public var sideInset: CGFloat = 0 {
        didSet {
            setCardSwiperInsets()
        }
    }
    /// Sets how much of the next card should be visible. Default is 0.
    @IBInspectable public var visibleNextCardHeight: CGFloat = 0 {
        didSet {
            setCardSwiperInsets()
        }
    }
    /// Vertical spacing between the focussed card and the bottom (next) card. Default is 40.
    @IBInspectable public var cardSpacing: CGFloat = 0 {
        willSet {
            flowLayout.minimumLineSpacing = newValue
        }
        didSet {
            setCardSwiperInsets()
        }
    }
    /// The transform animation that is shown on the top card when scrolling through the cards. Default is 0.05.
    @IBInspectable public var firstItemTransform: CGFloat = 0.05 {
        willSet {
            flowLayout.firstItemTransform = newValue
        }
    }
    /// Allows you to enable/disable the stacking effect. Default is `true`.
    @IBInspectable public var isStackingEnabled: Bool = true {
        willSet {
            flowLayout.isStackingEnabled = newValue
        }
    }
    /// Allows you to set the view to Stack at the Top or at the Bottom. Default is `true`.
    @IBInspectable public var isStackOnBottom: Bool = true {
        willSet {
            flowLayout.isStackOnBottom = newValue
        }
    }
    /// Sets how many cards of the stack are visible in the background. Default is 1.
    @IBInspectable public var stackedCardsCount: Int = 1 {
        willSet {
            flowLayout.stackedCardsCount = newValue
        }
    }
    /**
     Returns an array of indexes (as Int) that are currently visible in the `StackCardView`.
     This includes cards that are stacked (behind the focussed card).
     */
    public var indexesForVisibleCards: [Int] {
        var indexes: [Int] = []
        // Add each visible cell except the lowest one and return
        for cellIndexPath in self.stackCardView.indexPathsForVisibleItems {
            indexes.append(cellIndexPath.row)
        }
        return indexes.sorted()
    }
    /// The currently focussed card index.
    public var focussedCardIndex: Int? {
        let center = self.convert(self.stackCardView.center, to: self.stackCardView)
        if let indexPath = self.stackCardView.indexPathForItem(at: center) {
            return indexPath.row
        }
        return nil
    }

    public weak var delegate: StackCardDelegate?
    public weak var datasource: StackCardDatasource?

    /// We use this tapGestureRecognizer for the tap recognizer.
    fileprivate var tapGestureRecognizer: UITapGestureRecognizer!
    /// We use this tapGestureRecognizer for the tap recognizer.
    fileprivate var longPressGestureRecognizer: UILongPressGestureRecognizer!
    /// We use this horizontalPangestureRecognizer for the vertical panning.
    fileprivate var horizontalPangestureRecognizer: UIPanGestureRecognizer!
    /// Stores a `CGRect` with the area that is swipeable to the user.
    fileprivate var swipeAbleArea: CGRect?
    /// The `CardCell` that the user can (and is) moving.
    fileprivate var swipedCard: CardCell!
    /// Indicates if removal of a card is allowed. This is used to prevent rapid removal causing the datasource to get out of sync.
    fileprivate var isCardRemovalAllowed = false

    /// The flowlayout used in the collectionView.
    fileprivate lazy var flowLayout: StackCardFlowLayout = {
        let flowLayout = StackCardFlowLayout()
        flowLayout.firstItemTransform = firstItemTransform
        flowLayout.minimumLineSpacing = cardSpacing
        flowLayout.isPagingEnabled = true
        return flowLayout
    }()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        self.stackCardView.delegate = self
    }

    /**
     Inserts new cards at the specified indexes.

     Call this method to insert one or more new cards into the cardSwiper.
     You might do this when your data source object receives data for new items or in response to user interactions with the cardSwiper.
     - parameter indexes: An array of integers at which to insert the new card. This parameter must not be nil.
     */
    public func insertCards(at indexes: [Int]) {
        performUpdates {
            self.stackCardView.insertItems(at: indexes.map { (index) -> IndexPath in
                return convertIndexToIndexPath(for: index)
            })
        }
    }

    /**
     Deletes cards at the specified indexes.

     Call this method to delete one or more new cards from the cardSwiper.
     You might do this when you remove the items from your data source object or in response to user interactions with the cardSwiper.
     - parameter indexes: An array of integers at which to delete the card. This parameter must not be nil.
     */
    public func deleteCards(at indexes: [Int]) {
        performUpdates {
            self.stackCardView.deleteItems(at: indexes.map { (index) -> IndexPath in
                return self.convertIndexToIndexPath(for: index)
            })
        }
    }

    /**
     Moves an item from one location to another in the collection view.

     Use this method to reorganize existing cards. You might do this when you rearrange the items within your data source object or in response to user interactions with the cardSwiper. The cardSwiper updates the layout as needed to account for the move, animating cards into position as needed.

     - parameter atIndex: The index of the card you want to move. This parameter must not be nil.
     - parameter toIndex: The index of the card’s new location. This parameter must not be nil.
     */
    public func moveCard(at atIndex: Int, to toIndex: Int) {
        self.stackCardView.moveItem(at: convertIndexToIndexPath(for: atIndex), to: convertIndexToIndexPath(for: toIndex))
    }

    /**
     Returns the visible card object at the specified index.
     - parameter index: The index that specifies the item number of the cell.
     - returns: The card object at the corresponding index or nil if the cell is not visible or index is out of range.
     */
    public func cardForItem(at index: Int) -> CardCell? {
        return self.stackCardView.cellForItem(at: convertIndexToIndexPath(for: index)) as? CardCell
    }

    private func commonInit() {
        setupStackCardView()
        setupConstraints()
        setCardSwiperInsets()
        setupGestureRecognizer()
    }

    private func performUpdates(updateClosure: () -> Void) {
        UIView.performWithoutAnimation {
            self.stackCardView.performBatchUpdates({
                updateClosure()
            }, completion: { [weak self] _ in
                self?.stackCardView.collectionViewLayout.invalidateLayout()
            })
        }
    }
}

extension StackCard: CardDelegate {

    internal func willSwipeAway(cell: CardCell, swipeDirection: SwipeDirection) {
        self.stackCardView.isUserInteractionEnabled = false

        if let index = self.stackCardView.indexPath(for: cell)?.row {
            self.delegate?.willSwipeCardAway?(card: cell, index: index, swipeDirection: swipeDirection)
        }
    }

    internal func didSwipeAway(cell: CardCell, swipeDirection direction: SwipeDirection) {
        if let indexPathToRemove = self.stackCardView.indexPath(for: cell) {
            swipedCard = nil
            self.stackCardView.performBatchUpdates({
                self.stackCardView.deleteItems(at: [indexPathToRemove])
            }, completion: { [weak self] _ in
                self?.stackCardView.collectionViewLayout.invalidateLayout()
                self?.stackCardView.isUserInteractionEnabled = true
                self?.delegate?.didSwipeCardAway?(card: cell, index: indexPathToRemove.row, swipeDirection: direction)
                self?.isCardRemovalAllowed = false
            })
        }
    }

    func didCancelSwipe(cell: CardCell) {
        if let index = self.stackCardView.indexPath(for: cell)?.row {
            delegate?.didCancelSwipe?(card: cell, index: index)
            self.isCardRemovalAllowed = false
            swipedCard = nil
        }
    }

    internal func didDragCard(cell: CardCell, swipeDirection: SwipeDirection) {
        if let index = self.stackCardView.indexPath(for: cell)?.row {
            self.delegate?.didDragCard?(card: cell, index: index, swipeDirection: swipeDirection)
        }
    }
}

extension StackCard: UIGestureRecognizerDelegate {

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {

        if let panGestureRec = horizontalPangestureRecognizer {
            // When a horizontal pan is detected, we make sure to disable the collectionView.panGestureRecognizer so that it doesn't interfere with the sideswipe.
            if let direction = panGestureRec.direction, direction.isX {
                return false
            }
        }
        return true
    }

    /// We set up the `horizontalPangestureRecognizer` and attach it to the `collectionView`.
    fileprivate func setupGestureRecognizer() {
        tapGestureRecognizer = UITapGestureRecognizer.init(target: self, action: #selector(handleTap))
        tapGestureRecognizer.delegate = self
        stackCardView.addGestureRecognizer(tapGestureRecognizer)

        longPressGestureRecognizer = UILongPressGestureRecognizer.init(target: self, action: #selector(handleHold))
        longPressGestureRecognizer.delegate = self
        longPressGestureRecognizer.minimumPressDuration = 0.125
        longPressGestureRecognizer.cancelsTouchesInView = false
        stackCardView.addGestureRecognizer(longPressGestureRecognizer)

        horizontalPangestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        horizontalPangestureRecognizer.maximumNumberOfTouches = 1
        horizontalPangestureRecognizer.delegate = self
        stackCardView.addGestureRecognizer(horizontalPangestureRecognizer)
        stackCardView.panGestureRecognizer.maximumNumberOfTouches = 1
    }

    @objc fileprivate func handleTap(sender: UITapGestureRecognizer) {
        if let delegate = delegate {
            if let wasTapped = delegate.didTapCard {
                /// The taplocation relative to the collectionView.
                let locationInCollectionView = sender.location(in: stackCardView)

                if let tappedCardIndex = stackCardView.indexPathForItem(at: locationInCollectionView) {
                    wasTapped(stackCardView, tappedCardIndex.row)
                }
            }
        }
    }

    @objc fileprivate func handleHold(sender: UILongPressGestureRecognizer) {
        if let delegate = delegate {
            if let wasHeld = delegate.didHoldCard {
                /// The taplocation relative to the collectionView.
                let locationInCollectionView = sender.location(in: stackCardView)

                if let swipedCardIndex = stackCardView.indexPathForItem(at: locationInCollectionView) {
                    wasHeld(stackCardView, swipedCardIndex.row, sender.state)
                }
            }
        }
    }

    /**
     This function is called when a pan is detected inside the `collectionView`.
     We also take care of detecting if the pan gesture is inside the `swipeAbleArea` and we animate the cell if necessary.
     - parameter sender: The `UIPanGestureRecognizer` that detects the pan gesture. In this case `horizontalPangestureRecognizer`.
     */
    @objc fileprivate func handlePan(sender: UIPanGestureRecognizer) {

        guard isSideSwipingEnabled else { return }

        /// The translation of the finger performing the PanGesture.
        let translation = sender.translation(in: self)

        setSwipedCardIfDragging(pangestureRecognizer: sender)

        if swipedCard != nil {
            isCardRemovalAllowed = false
            /// The angle we pass for the swipe animation.
            let maximumRotation: CGFloat = 1.0
            let rotationStrength = min(translation.x / self.swipedCard.frame.width, maximumRotation)
            let angle = (CGFloat(Double.pi) / 10.0) * rotationStrength

            switch sender.state {
            case .began, .changed:
                swipedCard.animateCard(angle: angle, horizontalTranslation: translation.x)
            case .ended:
                swipedCard.endedPanAnimation(angle: angle)
            default:
                self.swipedCard.resetToCenterPosition()
            }
        }
    }

    fileprivate func setSwipedCardIfDragging(pangestureRecognizer gestureRec: UIPanGestureRecognizer) {
        /// The taplocation relative to the superview.
        let location = gestureRec.location(in: self)
        /// The taplocation relative to the collectionView.
        let locationInCollectionView = gestureRec.location(in: stackCardView)

        if let swipeArea = swipeAbleArea, swipeArea.contains(location), !stackCardView.isScrolling {
            if let swipedCardIndex = stackCardView.indexPathForItem(at: locationInCollectionView) {
                /// The card that is swipeable inside the SwipeAbleArea.
                self.swipedCard = self.stackCardView.cellForItem(at: swipedCardIndex) as? CardCell
            }
        }
    }
}

extension StackCard: UICollectionViewDelegate, UICollectionViewDataSource {

    /**
     Reloads all of the data for the StackCardView.
     
     Call this method sparingly when you need to reload all of the items in the StackCard. This causes the StackCardView to discard any currently visible items (including placeholders) and recreate items based on the current state of the data source object. For efficiency, the StackCardView only displays those cells and supplementary views that are visible. If the data shrinks as a result of the reload, the StackCardView adjusts its scrolling offsets accordingly.
     */
    public func reloadData() {
        stackCardView.reloadData()
    }

    /**
     Allows you to swipe a card away from code.
     The  `willSwipeCardAway` and `didSwipeCardAway` delegate functions will also be called when you use this function.
     You can use `willSwipeCardAway` to modify your DataSource.
     - parameter index: The index of the card you want to swipe away.
     - parameter direction: The `SwipeDirection` you want to swipe to.
     - parameter duration: The duration of the animation in seconds. Default is 0.3 seconds.
     - Returns: True if swiping away succeeds. False if swiping away failed.
     */
    public func swipeCardAwayProgrammatically(at index: Int, to direction: SwipeDirection, withDuration duration: TimeInterval = 0.3) -> Bool {
        guard swipedCard == nil, isCardRemovalAllowed else { return false }

        if let card = self.stackCardView.cellForItem(at: self.convertIndexToIndexPath(for: index)) as? CardCell {
            isCardRemovalAllowed = false
            card.animateOffScreenProgramatically(to: direction, withDuration: duration)
            return true
        }
        return false
    }

    /**
     Scrolls the collection view contents until the specified item is visible.
     If you want to scroll to a specific card from the start, make sure to call this function in `viewDidLayoutSubviews`
     instead of functions like `viewDidLoad` as the underlying collectionView needs to be loaded first for this to work.
     - parameter index: The index of the item to scroll into view.
     - parameter animated: Specify true to animate the scrolling behavior or false to adjust the scroll view’s visible content immediately.
     - Returns: True if scrolling succeeds. False if scrolling failed.
     Scrolling could fail due to the flowlayout not being set up yet or an incorrect index.
     */
    public func scrollToCard(at index: Int, animated: Bool) -> Bool {

        /**
         scrollToItem & scrollRectToVisible were giving issues with reliable scrolling,
         so we're using setContentOffset for the time being.
         See: https://github.com/JoniVR/StackCard/issues/23
         */
        guard
            let cellHeight = flowLayout.cellHeight,
            index >= 0,
            swipedCard == nil,
            index < stackCardView.numberOfItems(inSection: 0)
            else { return false }
        self.isCardRemovalAllowed = false
        let y = CGFloat(index) * (cellHeight + flowLayout.minimumLineSpacing) - topInset
        let point = CGPoint(x: stackCardView.contentOffset.x, y: y)
        stackCardView.setContentOffset(point, animated: animated)
        return true
    }

    /**
     Register a class for use in creating new CardCells.
     Prior to calling the dequeueReusableCell(withReuseIdentifier:for:) method of the collection view,
     you must use this method or the register(_:forCellWithReuseIdentifier:) method
     to tell the collection view how to create a new cell of the given type.
     If a cell of the specified type is not currently in a reuse queue,
     the StackCard uses the provided information to create a new cell object automatically.
     If you previously registered a class or nib file with the same reuse identifier,
     the class you specify in the cellClass parameter replaces the old entry.
     You may specify nil for cellClass if you want to unregister the class from the specified reuse identifier.
     - parameter cellClass: The class of a cell that you want to use in the StackCard
     identifier
     - parameter identifier: The reuse identifier to associate with the specified class. This parameter must not be nil and must not be an empty string.
     */
    public func register(_ cellClass: AnyClass?, forCellWithReuseIdentifier identifier: String) {
        self.stackCardView.register(cellClass, forCellWithReuseIdentifier: identifier)
    }

    /**
     Register a nib file for use in creating new collection view cells.
     Prior to calling the dequeueReusableCell(withReuseIdentifier:for:) method of the collection view,
     you must use this method or the register(_:forCellWithReuseIdentifier:) method
     to tell the collection view how to create a new cell of the given type.
     If a cell of the specified type is not currently in a reuse queue,
     the collection view uses the provided information to create a new cell object automatically.
     If you previously registered a class or nib file with the same reuse identifier,
     the object you specify in the nib parameter replaces the old entry.
     You may specify nil for nib if you want to unregister the nib file from the specified reuse identifier.
     - parameter nib: The nib object containing the cell object. The nib file must contain only one top-level object and that object must be of the type UICollectionViewCell.
     identifier
     - parameter identifier: The reuse identifier to associate with the specified nib file. This parameter must not be nil and must not be an empty string.
     */
    public func register(nib: UINib?, forCellWithReuseIdentifier identifier: String) {
        self.stackCardView.register(nib, forCellWithReuseIdentifier: identifier)
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return datasource?.numberOfCards(stackCardView: stackCardView) ?? 0
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let card = datasource?.cardForItemAt(stackCardView: stackCardView, cardForItemAt: indexPath.row) {
            card.delegate = self
            return card
        }
        return CardCell()
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.delegate?.didScroll?(stackCardView: self.stackCardView)
        isCardRemovalAllowed = false
    }

    public func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        isCardRemovalAllowed = false
    }

    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            delegate?.didEndScroll?(stackCardView: stackCardView)
            isCardRemovalAllowed = false
        }
    }

    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        delegate?.didEndScroll?(stackCardView: stackCardView)
        isCardRemovalAllowed = false
    }

    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        delegate?.didEndScroll?(stackCardView: stackCardView)
        isCardRemovalAllowed = false
    }
}

extension StackCard: UICollectionViewDelegateFlowLayout {

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

        let itemSize = calculateItemSize(for: indexPath.row)

        // set cellHeight in the custom flowlayout, we use this for paging calculations.
        flowLayout.cellHeight = itemSize.height

        if swipeAbleArea == nil {
            // Calculate and set the swipeAbleArea. We use this to determine wheter the cell can be swiped to the sides or not.
            let swipeAbleAreaOriginY = collectionView.frame.origin.y + collectionView.contentInset.top
            self.swipeAbleArea = CGRect(x: 0, y: swipeAbleAreaOriginY, width: self.frame.width, height: itemSize.height)
        }
        return itemSize
    }

    fileprivate func calculateItemSize(for index: Int) -> CGSize {

        let cellWidth: CGFloat!
        let cellHeight: CGFloat!
        let xInsets = sideInset * 2
        let yInsets = cardSpacing + visibleNextCardHeight + topInset

        // get size from delegate if the sizeForItem function is called.
        if let customSize = delegate?.sizeForItem?(stackCardView: stackCardView, index: index) {
            // set custom sizes and make sure sizes are not negative, if they are, don't subtract the insets.
            cellWidth = customSize.width - (customSize.width - xInsets > 0 ? xInsets : 0)
            cellHeight = customSize.height - (customSize.height - yInsets > 0 ? yInsets : 0)
        } else {
            cellWidth = stackCardView.frame.size.width - xInsets
            cellHeight = stackCardView.frame.size.height - yInsets
        }
        return CGSize(width: cellWidth, height: cellHeight)
    }

    fileprivate func setupStackCardView() {
        stackCardView = StackCardView(frame: self.frame, collectionViewLayout: flowLayout)
        stackCardView.decelerationRate = UIScrollView.DecelerationRate.fast
        stackCardView.backgroundColor = UIColor.clear
        stackCardView.showsVerticalScrollIndicator = false
        stackCardView.dataSource = self
        self.addSubview(stackCardView)
    }

    fileprivate func setupConstraints() {
        stackCardView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.stackCardView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            self.stackCardView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            self.stackCardView.topAnchor.constraint(equalTo: self.topAnchor),
            self.stackCardView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
    }

    fileprivate func setCardSwiperInsets() {
        let bottomInset = visibleNextCardHeight + flowLayout.minimumLineSpacing
        stackCardView.contentInset = UIEdgeInsets(top: topInset, left: sideInset, bottom: bottomInset, right: sideInset)
    }
}
