//
//  ClockView.swift
//  drawAClock
//
//  Created by Aleksandr on 4/2/19.
//  Copyright © 2019 Aleksandr. All rights reserved.
//

import UIKit

class ClockView: UIView {
    
    let secondLayer = CAShapeLayer()
    let minuteLayer = CAShapeLayer()
    let hourLayer = CAShapeLayer()
    var radius: CGFloat = 0
    var dateSetDate: Date = Date()
    var date: Date = Date() {
        didSet {
            dateSetDate = Date()
        }
    }
    
    var strokeWidth: CGFloat = 3.0
    var boundsCenter: CGPoint = .zero
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        NotificationCenter.default.addObserver(self, selector: #selector(appWillBecomeActive), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override var frame: CGRect {
        didSet { radius = min(bounds.width, bounds.height) / 2.5 - ceil(strokeWidth / 2) }
    }
    
    @objc func appWillBecomeActive() {
        setNeedsDisplay()
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        boundsCenter = CGPoint(x: bounds.width / 2, y: bounds.height / 2)
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        setupClockFace(context: ctx, radius: radius)
        secondMarkers(ctx: ctx, x: boundsCenter.x, y: boundsCenter.y, radius: radius, sides: 60, color: .white)
        drawText(rect: rect, ctx: ctx, x: boundsCenter.x, y: boundsCenter.y, radius: radius, sides: 12, color: .white)
        secondArrow()
        minuteArrow()
        hourArrow()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        date = date.addingTimeInterval(-dateSetDate.timeIntervalSinceNow)
        contentMode = .center
        boundsCenter = CGPoint(x: bounds.width / 2, y: bounds.height / 2)
        secondArrow()
        minuteArrow()
        hourArrow()
    }

    func image(time: Date) -> UIImage {
        assert(frame.width == frame.height)
        date = time
        radius = bounds.width / 2 - ceil(strokeWidth / 2)
        layer.backgroundColor = UIColor.clear.cgColor
        layer.isOpaque = false
        return UIGraphicsImageRenderer(bounds: frame).image { rendererContext in
            layer.render(in: rendererContext.cgContext)
        }
    }
    
    class func getImage(time: Date, size: CGSize) -> UIImage {
        let cv = ClockView(frame: CGRect(origin: .zero, size: size))
        return cv.image(time: time)
    }
    
    func setupClockFace(context: CGContext, radius: CGFloat) {
        let clockFace = UIBezierPath(arcCenter: boundsCenter, radius: CGFloat(radius), startAngle: 0, endAngle: CGFloat.pi * 2, clockwise: true)
        UIColor.lightGray.setFill()
        clockFace.fill()
        UIColor.black.setStroke()
        clockFace.stroke()
        context.addPath(clockFace.cgPath)
    }
    
    func circleCircumferencePoints(sides: Int, x: CGFloat, y: CGFloat, radius: CGFloat, adjustment: CGFloat = 0) -> [CGPoint] {
        let angle = degree2radian(a: 360 / CGFloat(sides))
        var i = sides
        var points = [CGPoint]()
        while points.count <= sides {
            let xpo = x - radius * cos(angle * CGFloat(i) + degree2radian(a: adjustment))
            let ypo = y - radius * sin(angle * CGFloat(i) + degree2radian(a: adjustment))
            points.append(CGPoint(x: xpo, y: ypo))
            i -= 1;
        }
        return points
    }
    
    func secondMarkers(ctx: CGContext, x: CGFloat, y: CGFloat, radius: CGFloat, sides: Int, color: UIColor) {
        // retrieve points
        let points = circleCircumferencePoints(sides: sides, x: x, y: y, radius: radius)
        // create path
        let path = CGMutablePath()
        // determine length of marker as a fraction of the total radius
        var divider: CGFloat
        
        for (p, q) in points.enumerated() {
            divider = p % 5 == 0 ? 1 / 8 : 1 / 16
            let xn = q.x + divider * (x - q.x)
            let yn = q.y + divider * (y - q.y)
            // build path
            path.move(to: CGPoint(x: q.x, y: q.y))
            path.addLine(to: CGPoint(x: xn, y: yn))
            path.closeSubpath()
            // add path to context
            ctx.addPath(path)
        }
        // set path color
        ctx.setStrokeColor(color.cgColor)
        ctx.setLineWidth(strokeWidth)
        ctx.strokePath()
    }
    
    func drawText(rect: CGRect, ctx: CGContext, x: CGFloat, y: CGFloat, radius: CGFloat, sides: Int, color: UIColor) {
        ctx.translateBy(x: 0, y: rect.height)
        ctx.scaleBy(x: 1, y: -1)
        // dictates on how inset the ring of numbers will be
        let inset:CGFloat = radius / 4.5
        // An adjustment of 270 degrees to position numbers correctly
        let points = circleCircumferencePoints(sides: sides,x: x,y: y,radius: radius - inset,adjustment: 270)
        _ = CGMutablePath()
        // see
        let aFont = UIFont(name: "Optima-Bold", size: radius / 7)
        let attr = [NSAttributedString.Key.font: aFont]
        for (p, q) in points.enumerated() {
            if p > 0 {
                // create the attributed string
                guard let text = CFAttributedStringCreate(nil, "\(p)" as CFString, attr as NSDictionary) else { return }
                // create the line of text
                let line = CTLineCreateWithAttributedString(text)
                // retrieve the bounds of the text
                let bounds = CTLineGetBoundsWithOptions(line, CTLineBoundsOptions.useOpticalBounds)
                // set the line width to stroke the text with
                //                ctx.setLineWidth(1)
                // set the drawing mode to stroke
                ctx.setTextDrawingMode(.fill)
                // Set text position and draw the line into the graphics context, text length and height is adjusted for
                let xn = q.x - bounds.width / 2
                let yn = q.y - bounds.midY
                ctx.textPosition = CGPoint(x: xn, y: yn)
                // draw the line of text
                CTLineDraw(line, ctx)
            }
        }
    }
    
    func time() -> (h: Int, m: Int, s: Int) {
        let clock = Calendar.current.dateComponents([.hour, .minute, .second], from: date)
        guard let hour = clock.hour, let minute = clock.minute, let second = clock.second else { return (h: 0, m: 0, s: 0) }
        return (h: hour, m: minute, s: second)
    }
    
    func timeCoords(x: CGFloat, y: CGFloat, time: (h:Int,m:Int,s:Int), radius: CGFloat, adjustment: CGFloat = 90) -> (h: CGPoint, m:  CGPoint, s: CGPoint) {
        var r = radius // radius of circle
        var points = [CGPoint]()
        var angle = degree2radian(a: 6)
        func newPoint (t: Int) {
            let xpo = x - r * cos(angle * CGFloat(t) + degree2radian(a: adjustment))
            let ypo = y - r * sin(angle * CGFloat(t) + degree2radian(a: adjustment))
            points.append(CGPoint(x: xpo, y: ypo))
        }
        // work out hours first
        var hours = time.h
        if hours > 12 { hours = hours - 12 }
        let hoursInSeconds = time.h * 3600 + time.m * 60 + time.s
        newPoint(t: hoursInSeconds * 5 / 3600)
        // work out minutes second
        r = radius * 1.25
        let minutesInSeconds = time.m * 60 + time.s
        newPoint(t: minutesInSeconds / 60)
        // work out seconds last
        r = radius * 1.5
        newPoint(t: time.s)
        return (h: points[0], m: points[1], s:points[2])
    }
    
    func degree2radian(a: CGFloat) -> CGFloat {
        return CGFloat.pi * a / 180
    }
    
    func secondArrow() {
        let time = timeCoords(x: boundsCenter.x, y: boundsCenter.y, time: self.time(), radius: radius * 0.45)
        let secondPath = UIBezierPath()
        
        secondLayer.frame = bounds
        secondPath.move(to: boundsCenter)
        secondPath.addLine(to: CGPoint(x: time.s.x, y: time.s.y))
        secondLayer.path = secondPath.cgPath
        secondLayer.lineWidth = 1
        secondLayer.lineCap = CAShapeLayerLineCap.round
        secondLayer.fillColor = UIColor.red.cgColor
        secondLayer.strokeColor = UIColor.red.cgColor
        layer.addSublayer(secondLayer)
        rotateLayer(currentLayer: secondLayer, dur: 60)
    }
    
    func minuteArrow() {
        let time = timeCoords(x: boundsCenter.x, y: boundsCenter.y, time: self.time(), radius: radius * 0.45)
        let minutePath = CGMutablePath()
        
        minuteLayer.frame = bounds
        minutePath.move(to: boundsCenter)
        minutePath.addLine(to: CGPoint(x: time.m.x, y: time.m.y))
        minuteLayer.path = minutePath
        minuteLayer.lineWidth = 1
        minuteLayer.lineCap = CAShapeLayerLineCap.round
        minuteLayer.strokeColor = UIColor.black.cgColor
        layer.addSublayer(minuteLayer)
        rotateLayer(currentLayer: minuteLayer, dur: 60 * 60)
    }
    
    func hourArrow() {
        let time = timeCoords(x: boundsCenter.x, y: boundsCenter.y, time: self.time(), radius: radius * 0.45 - 10)
        let hourPath = CGMutablePath()
        
        hourLayer.frame = bounds
        hourPath.move(to: boundsCenter)
        hourPath.addLine(to: CGPoint(x: time.h.x, y: time.h.y))
        hourLayer.path = hourPath
        hourLayer.lineWidth = 1
        hourLayer.lineCap = CAShapeLayerLineCap.round
        hourLayer.strokeColor = UIColor.black.cgColor
        layer.addSublayer(hourLayer)
        rotateLayer(currentLayer: hourLayer, dur: 60 * 60 * 24)
    }
    
    func rotateLayer(currentLayer: CALayer, dur: CFTimeInterval) {
        let angle = degree2radian(a: 360)
        let theAnimation = CABasicAnimation(keyPath:"transform.rotation.z")
        
        theAnimation.duration = dur
        theAnimation.timingFunction = CAMediaTimingFunction(name: .linear)
        theAnimation.fromValue = 0
        theAnimation.repeatCount = Float.infinity
        theAnimation.toValue = angle
        currentLayer.add(theAnimation, forKey: "rotate")
    }
    
}
