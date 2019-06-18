import UIKit

public enum VAWeekDaysSymbolsType {
    case short, veryShort
    
    func names(from calendar: Calendar) -> [String] {
        switch self {
        case .short:
            return calendar.shortWeekdaySymbols
        case .veryShort:
            return calendar.veryShortWeekdaySymbols
        }
    }
    
}

public struct VAWeekDaysViewAppearance {
    
    let symbolsType: VAWeekDaysSymbolsType
    let weekDayTextColor: UIColor
    let weekDayTextFont: UIFont
    let leftInset: CGFloat
    let rightInset: CGFloat
    let separatorBackgroundColor: UIColor
    let calendar: Calendar
    
    public init(
        symbolsType: VAWeekDaysSymbolsType = .veryShort,
        weekDayTextColor: UIColor = .black,
        weekDayTextFont: UIFont = UIFont.systemFont(ofSize: 15),
        leftInset: CGFloat = 10.0,
        rightInset: CGFloat = 10.0,
        separatorBackgroundColor: UIColor = .lightGray,
        calendar: Calendar = Calendar.current) {
        self.symbolsType = symbolsType
        self.weekDayTextColor = weekDayTextColor
        self.weekDayTextFont = weekDayTextFont
        self.leftInset = leftInset
        self.rightInset = rightInset
        self.separatorBackgroundColor = separatorBackgroundColor
        self.calendar = calendar
    }
    
}

public protocol VAWeekDaysViewDelegate: class {
    func didSelectDay(with dayLabel: String)
}

public class VAWeekDaysView: UIView {
    
    public var appearance = VAWeekDaysViewAppearance() {
        didSet {
            setupView()
        }
    }
    
    public var delegate: VAWeekDaysViewDelegate?
    
    private let separatorView = UIView()
    private var dayButtons = [UIButton]()
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        
        setupView()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        setupView()
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        let width = frame.width - (appearance.leftInset + appearance.rightInset)
        let dayWidth = width / CGFloat(dayButtons.count)
        
        dayButtons.enumerated().forEach { index, button in
            let x = index == 0 ? appearance.leftInset : dayButtons[index - 1].frame.maxX

            button.frame = CGRect(
                x: x,
                y: 0,
                width: dayWidth,
                height: self.frame.height
            )
        }
        
        let separatorHeight = 1 / UIScreen.main.scale
        let separatorY = frame.height - separatorHeight
        separatorView.frame = CGRect(
            x: appearance.leftInset,
            y: separatorY,
            width: width,
            height: separatorHeight
        )
    }
    
    private func setupView() {
        subviews.forEach { $0.removeFromSuperview() }
        dayButtons = []
        
        let names = getWeekdayNames()
        names.enumerated().forEach { index, name in
            let btn = UIButton()
            btn.setTitle(name, for: .normal)
            btn.tag = index
            btn.titleLabel?.font = appearance.weekDayTextFont
            btn.setTitleColor(appearance.weekDayTextColor, for: .normal)
            btn.addTarget(self, action: #selector(weekDayClicked(btn:)), for: .touchUpInside)
            dayButtons.append(btn)
            addSubview(btn)
        }
        
        separatorView.backgroundColor = appearance.separatorBackgroundColor
        addSubview(separatorView)
        layoutSubviews()
    }
    
    @objc
    private func weekDayClicked(btn: UIButton){
        let names = getWeekdayNames()
        let day = names[btn.tag]
        self.delegate?.didSelectDay(with: day)
    }
    
    private func getWeekdayNames() -> [String] {
        let symbols = appearance.symbolsType.names(from: appearance.calendar)
        
        if appearance.calendar.firstWeekday == 1 {
            return symbols
        } else {
            let allDaysWihoutFirst = Array(symbols[appearance.calendar.firstWeekday - 1..<symbols.count])
            return allDaysWihoutFirst + symbols[0..<appearance.calendar.firstWeekday - 1]
        }
    }
    
}
