import UIKit

class ExampleViewController: UIViewController, VerticalCardSwiperDelegate, VerticalCardSwiperDatasource {

    @IBOutlet private var cardSwiper: VerticalCardSwiper!

    override func viewDidLoad() {
        super.viewDidLoad()

        cardSwiper.delegate = self
        cardSwiper.datasource = self
        cardSwiper.isSideSwipingEnabled = true
        cardSwiper.isStackingEnabled = true
        cardSwiper.stackedCardsCount = 3
        // register cardcell for storyboard use
        cardSwiper.register(nib: UINib(nibName: "ExampleCell", bundle: nil), forCellWithReuseIdentifier: "ExampleCell")
    }

    @objc func nextScroll(_ sender: UITapGestureRecognizer) {
        if let currentIndex = cardSwiper.focussedCardIndex {
            _ = cardSwiper.scrollToCard(at: currentIndex + 1, animated: true)
        }
    }

    func cardForItemAt(verticalCardSwiperView: VerticalCardSwiperView, cardForItemAt index: Int) -> CardCell {

        if let cardCell = verticalCardSwiperView.dequeueReusableCell(withReuseIdentifier: "ExampleCell", for: index) as? ExampleCardCell {
            cardCell.bottomButtonView.isUserInteractionEnabled = true
            cardCell.bottomButtonView.addGestureRecognizer(UITapGestureRecognizer.init(target: self, action: #selector(self.nextScroll(_:))))
            cardCell.topView.backgroundColor = cardCell.setRandomBackgroundColor()
            cardCell.topView.isHidden = true
            return cardCell
        }
        return CardCell()
    }

    func numberOfCards(verticalCardSwiperView: VerticalCardSwiperView) -> Int {
        return 3
    }
    
    func didEndScroll(verticalCardSwiperView: VerticalCardSwiperView) {
        if let currentIndex = cardSwiper.focussedCardIndex {
            if let cell = verticalCardSwiperView.cellForItem(at: IndexPath.init(item: currentIndex - 1, section: 0)) as? ExampleCardCell {
                cell.backgroundColor = cell.topView.backgroundColor
                cell.topView.isHidden = false
            }
        }
        
//        print(cardSwiper.gesture)
    }

    func didTapCard(verticalCardSwiperView: VerticalCardSwiperView, index: Int) {
        if cardSwiper.focussedCardIndex != nil {
            _ = cardSwiper.scrollToCard(at: index, animated: true)
            if let cell = verticalCardSwiperView.cellForItem(at: IndexPath.init(item: index, section: 0)) as? ExampleCardCell {
                cell.topView.isHidden = true
                cell.backgroundColor = #colorLiteral(red: 0.1008155271, green: 0.1092368588, blue: 0.1608650684, alpha: 1)
            }
        }
    }
}
