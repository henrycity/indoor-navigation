import UIKit

class DrawLine: UIView {
    
    
    override func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        
        context!.setLineWidth(2.0)
        context!.setStrokeColor(UIColor.green.cgColor)
        
        context!.move(to:CGPoint(x:214, y:187))
        context!.addLine(to:CGPoint(x:100,y:150))
        context!.strokePath()

    }
    
    func draw2(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        
        context!.setLineWidth(2.0)
        context!.setStrokeColor(UIColor.red.cgColor)
        
        context!.move(to:CGPoint(x:214, y:187))
        context!.addLine(to:CGPoint(x:138,y:226))
        context!.strokePath()
        
    }
    
    func draw3(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        
        context!.setLineWidth(2.0)
        context!.setStrokeColor(UIColor.blue.cgColor)
        
        context!.move(to:CGPoint(x:100, y:150))
        context!.addLine(to:CGPoint(x:138,y:226))
        context!.strokePath()
        
    }
}
