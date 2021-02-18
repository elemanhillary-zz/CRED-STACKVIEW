import Foundation

/// This datasource is used for providing data to the `VerticalCardSwiper`.
public protocol VerticalCardSwiperDatasource: class {

    /**
     Sets the number of cards for the `UICollectionView` inside the VerticalCardSwiperController.
     - parameter verticalCardSwiperView: The `VerticalCardSwiperView` where we set the amount of cards.
     - returns: an `Int` with the amount of cards we want to show.
     */
    func numberOfCards(verticalCardSwiperView: VerticalCardSwiperView) -> Int

    /**
     Asks your data source object for the cell that corresponds to the specified item in the `VerticalCardSwiper`.
     Your implementation of this method is responsible for creating, configuring, and returning the appropriate `CardCell` for the given item.
     - parameter verticalCardSwiperView: The `VerticalCardSwiperView` that will display the `CardCell`.
     - parameter index: The that the `CardCell` should be shown at.
     - returns: A CardCell object. The default value is an empty CardCell object.
    */
    func cardForItemAt(verticalCardSwiperView: VerticalCardSwiperView, cardForItemAt index: Int) -> CardCell
}
