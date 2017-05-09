import UIKit

class DrawLine: UIView {
    
    
    override func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        
        context!.setLineWidth(3.0)
        context!.setStrokeColor(UIColor.green.cgColor)
        
        context!.move(to:CGPoint(x:50, y:60))
        context!.addLine(to:CGPoint(x:100,y:200))
        context!.strokePath()

    }
}
