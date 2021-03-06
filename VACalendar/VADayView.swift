//
//  VADayView.swift
//  VACalendar
//
//  Created by Anton Vodolazkyi on 20.02.18.
//  Copyright © 2018 Vodolazkyi. All rights reserved.
//

import UIKit

@objc
public protocol VADayViewAppearanceDelegate: class {
    @objc optional func font(for state: VADayState) -> UIFont
    @objc optional func textColor(for state: VADayState) -> UIColor
    @objc optional func holidayTextColor() -> UIColor
    @objc optional func textBackgroundColor(for state: VADayState) -> UIColor
    @objc optional func backgroundColor(for state: VADayState) -> UIColor
    @objc optional func borderWidth(for state: VADayState) -> CGFloat
    @objc optional func borderColor(for state: VADayState) -> UIColor
    @objc optional func dotBottomVerticalOffset(for state: VADayState) -> CGFloat
    @objc optional func isHoliday(day date: Date) -> Bool
    @objc optional func isWorkingDate(_ date: Date) -> Bool
    @objc optional func getLoadedBufferAngles(for date: Date) -> [CGFloat]
    @objc optional func getCicleProgressColor() -> UIColor
    @objc optional func getCicrcleProgressBackgroundColor() -> UIColor
    @objc optional func getWorkDayColor() -> UIColor
    @objc optional func shape() -> VADayShape
    // percent of the selected area to be painted
    @objc optional func selectedArea() -> CGFloat
}

protocol VADayViewDelegate: class {
    func dayStateChanged(_ day: VADay)
}

class VADayView: UIView {
    
    var day: VADay
    weak var delegate: VADayViewDelegate?
    
    weak var dayViewAppearanceDelegate: VADayViewAppearanceDelegate? {
        return (superview as? VAWeekView)?.dayViewAppearanceDelegate
    }
    
    private var dotStackView: UIStackView {
        let stack = UIStackView()
        stack.distribution = .fillEqually
        stack.axis = .horizontal
        stack.spacing = dotSpacing
        return stack
    }
    
    private let dotSpacing: CGFloat = 5
    private let dotSize: CGFloat = 5
    private var supplementaryViews = [UIView]()
    private let dateLabel = UILabel()
    
    override func draw(_ rect: CGRect) {
        
        guard
            let angles = dayViewAppearanceDelegate?.getLoadedBufferAngles?(for: day.date),
            angles.count >= 2
        else {
            return
        }
        
        let isWorkingDay = dayViewAppearanceDelegate?.isWorkingDate?(day.date) ?? false
        
        var startAngle = angles.first
        var endAngle = angles.last
        var drawWorkingCircle = false
        
        if isWorkingDay &&
            startAngle == 0 &&
            endAngle == 0
        {
            startAngle = 0
            endAngle = 2 * CGFloat(Float.pi)
            drawWorkingCircle = true
        }
        
        guard let startAngle = startAngle,
              let endAngle = endAngle
        else {
            return
        }
        
        let shortestSide: CGFloat = (frame.width < frame.height ? frame.width : frame.height)
        let side: CGFloat = shortestSide * (dayViewAppearanceDelegate?.selectedArea?() ?? 0.8)
        let radius = side / 2
        let centerPoint = CGPoint(x: rect.width / 2, y: rect.height / 2)

        let path = UIBezierPath(arcCenter: centerPoint, radius: radius, startAngle: CGFloat(startAngle), endAngle: CGFloat(endAngle), clockwise: true)

        layer.sublayers?.forEach { sublayer in
            if sublayer.name == "progress_layer" || sublayer.name == "progress_background_layer" {
                sublayer.removeFromSuperlayer()
            }
        }
        
        if startAngle != 0 && endAngle != 0 {
            let pathBack = UIBezierPath(arcCenter: centerPoint, radius: radius, startAngle: CGFloat(3*Float.pi / 2), endAngle: CGFloat(3*Float.pi / 2 - 0.001), clockwise: true)
            
            let layerBack = CAShapeLayer()
            layerBack.fillColor = UIColor.clear.cgColor
            layerBack.strokeColor = UIColor.lightGray.cgColor
            layerBack.name = "progress_background_layer"
            layerBack.backgroundColor = UIColor.clear.cgColor
            layerBack.lineWidth = 2.0
            layerBack.shouldRasterize = false
            layerBack.path = pathBack.cgPath
            layer.addSublayer(layerBack)
        }
        
        let progressColor = drawWorkingCircle ? (dayViewAppearanceDelegate?.getWorkDayColor?() ?? .blue).cgColor : (dayViewAppearanceDelegate?.getCicleProgressColor?() ?? UIColor.black).cgColor
        
        let layerFront = CAShapeLayer()
        layerFront.fillColor = UIColor.clear.cgColor
        layerFront.strokeColor = progressColor
        layerFront.name = "progress_layer"
        layerFront.backgroundColor = UIColor.clear.cgColor
        layerFront.lineWidth = 2.0
        layerFront.shouldRasterize = false
        layerFront.path = path.cgPath
        layer.addSublayer(layerFront)
    }
    
    init(day: VADay) {
        self.day = day
        super.init(frame: .zero)
        
        self.day.stateChanged = { [weak self] state in
            self?.setState(state)
        }
        
        self.day.supplementariesDidUpdate = { [weak self] in
            self?.updateSupplementaryViews()
        }
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapSelect))
        addGestureRecognizer(tapGesture)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupDay() {
        let shortestSide: CGFloat = (frame.width < frame.height ? frame.width : frame.height)
        let side: CGFloat = shortestSide * (dayViewAppearanceDelegate?.selectedArea?() ?? 0.8)
        
        dateLabel.font = dayViewAppearanceDelegate?.font?(for: day.state) ?? dateLabel.font
        dateLabel.text = VAFormatters.dayFormatter.string(from: day.date)
        dateLabel.textAlignment = .center
        dateLabel.frame = CGRect(
            x: 0,
            y: 0,
            width: side,
            height: side
        )
        dateLabel.center = CGPoint(x: frame.width / 2, y: frame.height / 2)
        
        setState(day.state)
        addSubview(dateLabel)
        updateSupplementaryViews()
    }
    
    @objc
    private func didTapSelect() {
        guard day.state != .out && day.state != .unavailable else { return }
        delegate?.dayStateChanged(day)
    }
    
    private func setState(_ state: VADayState) {
        
        if dayViewAppearanceDelegate?.shape?() == .circle  {
            dateLabel.clipsToBounds = true
            dateLabel.layer.cornerRadius = dateLabel.frame.height / 2
        }
        
        backgroundColor = dayViewAppearanceDelegate?.backgroundColor?(for: state) ?? backgroundColor
        let isHoliday = dayViewAppearanceDelegate?.isHoliday?(day: day.date)
        
        dateLabel.layer.borderColor = UIColor.clear.cgColor
        dateLabel.layer.borderWidth = 0
        dateLabel.textColor = dayViewAppearanceDelegate?.textColor?(for: state) ?? dateLabel.textColor
        
        if isHoliday == true {
            if state == .selected {
                dateLabel.layer.borderColor = dayViewAppearanceDelegate?.borderColor?(for: state).cgColor ?? layer.borderColor
                dateLabel.layer.borderWidth = dayViewAppearanceDelegate?.borderWidth?(for: state) ?? dateLabel.layer.borderWidth
            } else {
                dateLabel.textColor = dayViewAppearanceDelegate?.holidayTextColor?() ?? dateLabel.textColor
            }
        }
        
        dateLabel.backgroundColor = dayViewAppearanceDelegate?.textBackgroundColor?(for: state) ?? dateLabel.backgroundColor
        updateSupplementaryViews()
    }
    
    private func updateSupplementaryViews() {
        removeAllSupplementaries()
        
        day.supplementaries.forEach { supplementary in
            switch supplementary {
            case .bottomDots(let colors):
                let stack = dotStackView
                
                colors.forEach { color in
                    let dotView = VADotView(size: dotSize, color: color)
                    stack.addArrangedSubview(dotView)
                }
                let spaceOffset = CGFloat(colors.count - 1) * dotSpacing
                let stackWidth = CGFloat(colors.count) * dotSpacing + spaceOffset
                
                let verticalOffset = dayViewAppearanceDelegate?.dotBottomVerticalOffset?(for: day.state) ?? 2
                stack.frame = CGRect(x: 0, y: dateLabel.frame.maxY + verticalOffset, width: stackWidth, height: dotSize)
                stack.center.x = dateLabel.center.x
                addSubview(stack)
                supplementaryViews.append(stack)
            }
        }
    }
    
    private func removeAllSupplementaries() {
        supplementaryViews.forEach { $0.removeFromSuperview() }
        supplementaryViews = []
    }
    
}
