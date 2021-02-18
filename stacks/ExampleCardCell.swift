import Foundation
import UIKit

class ExampleCardCell: CardCell {
    @IBOutlet weak var bottomButtonView: UIView!
    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var buttonViewTitle: UILabel!
    /**
     We use this function to calculate and set a random backgroundcolor.
     */
    public func setRandomBackgroundColor() -> UIColor {
        let randomRed: CGFloat = CGFloat(arc4random()) / CGFloat(UInt32.max)
        let randomGreen: CGFloat = CGFloat(arc4random()) / CGFloat(UInt32.max)
        let randomBlue: CGFloat = CGFloat(arc4random()) / CGFloat(UInt32.max)
        return UIColor(red: randomRed, green: randomGreen, blue: randomBlue, alpha: 1.0)
    }

    override func prepareForReuse() {
        super.prepareForReuse()

    }

    override func layoutSubviews() {
        let corners = UIBezierPath.init(roundedRect: self.bounds, byRoundingCorners: [.topLeft, .topRight], cornerRadii: CGSize(width: 20, height: 20))
        let shape = CAShapeLayer.init()
        shape.path = corners.cgPath
        self.layer.mask = shape
    
        super.layoutSubviews()
    }
}
