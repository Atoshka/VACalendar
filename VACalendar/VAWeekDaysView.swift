import UIKit

public enum VAWeekDaysSymbolsType {
    case short, veryShort
    
    func names(from calendar: Calendar) -> [String] {
        switch self {
        case .short:
            return calendar.shortWeekdaySymbols.map { $0.uppercased() }
        case .veryShort:
            return calendar.veryShortWeekdaySymbols.map { $0.uppercased() }
        }
    }
    
}

public struct VAWeekDaysViewAppearance {
    
    let symbolsType: VAWeekDaysSymbolsType
    let weekDayTextColor: UIColor
    let selectedWeekDayTextColor: UIColor
    let weekDayTextFont: UIFont
    let leftInset: CGFloat
    let rightInset: CGFloat
    let separatorBackgroundColor: UIColor
    let calendar: Calendar
    let borderColor: UIColor
    let selectedBorderColor: UIColor
    let selectedFilledColor: UIColor
    
    public init(
        symbolsType: VAWeekDaysSymbolsType = .veryShort,
        weekDayTextColor: UIColor = .black,
        selectedWeekDayTextColor: UIColor = .white,
        weekDayTextFont: UIFont = UIFont.systemFont(ofSize: 15),
        leftInset: CGFloat = 10.0,
        rightInset: CGFloat = 10.0,
        separatorBackgroundColor: UIColor = .lightGray,
        calendar: Calendar = Calendar.current,
        borderColor: UIColor = .lightGray,
        selectedBorderColor: UIColor = .blue,
        selectedFilledColor: UIColor = .blue
        
        ) {
        self.symbolsType = symbolsType
        self.weekDayTextColor = weekDayTextColor
        self.selectedWeekDayTextColor = selectedWeekDayTextColor
        self.weekDayTextFont = weekDayTextFont
        self.leftInset = leftInset
        self.rightInset = rightInset
        self.separatorBackgroundColor = separatorBackgroundColor
        self.calendar = calendar
        self.borderColor = borderColor
        self.selectedBorderColor = selectedBorderColor
        self.selectedFilledColor = selectedFilledColor
    }
    
}

public protocol VAWeekDaysViewDelegate: class {
    func didTapDay(with dayLabel: String, selected: Bool)
    
}

public protocol VAWeekDaysViewDataSource: class {
    // Used to change selection style for week day button if needed otherwice return false, title should be localized week day value with .short format
    func weekDaysSelectionStates(for title: String) -> Bool
}

public class VAWeekDaysView: UIView {
    
    public var appearance = VAWeekDaysViewAppearance() {
        didSet {
            setupView()
        }
    }
    
    public var delegate: VAWeekDaysViewDelegate?
    public var dataSource: VAWeekDaysViewDataSource?
    
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
    
    public func reloadData() {
        dayButtons.enumerated().forEach { (arg) in
            
            guard
                let title = arg.element.titleLabel?.text,
                let dataSource = self.dataSource
                else {
                    assert(false, "Error!")
                    return
            }
            arg.element.isSelected = dataSource.weekDaysSelectionStates(for: title)
            
            updateStyle(for: arg.element)
        }
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        let offsetSize = appearance.leftInset + appearance.rightInset + appearance.leftInset * CGFloat(dayButtons.count - 1)
        let width = frame.width - offsetSize
        
        let daySize = width / CGFloat(dayButtons.count)
        
        dayButtons.enumerated().forEach { index, button in
            let x = index == 0 ? appearance.leftInset : (dayButtons[index - 1].frame.maxX + appearance.leftInset)
            
            button.frame = CGRect(
                x: x,
                y: 0,
                width: daySize,
                height: daySize
            )
            
            button.layer.cornerRadius = button.frame.size.width / 2
        }
        
        let separatorHeight = 1 / UIScreen.main.scale
        let separatorY = frame.height - separatorHeight
        separatorView.frame = CGRect(
            x: appearance.leftInset,
            y: separatorY,
            width: width + appearance.leftInset * CGFloat(dayButtons.count - 1),
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
            btn.layer.borderColor = appearance.borderColor.cgColor
            btn.layer.borderWidth = 1
            
            btn.addTarget(self, action: #selector(weekDayClicked(btn:)), for: .touchUpInside)
            dayButtons.append(btn)
            addSubview(btn)
        }
        
        separatorView.backgroundColor = appearance.separatorBackgroundColor
        addSubview(separatorView)
        layoutSubviews()
    }
    
    private func updateStyle(for button: UIButton) {
        if button.isSelected {
            button.setTitleColor(appearance.selectedWeekDayTextColor, for: .selected)
            button.layer.borderColor = appearance.selectedBorderColor.cgColor
            button.backgroundColor = appearance.selectedFilledColor
        } else {
            button.layer.borderColor = appearance.borderColor.cgColor
            button.setTitleColor(appearance.weekDayTextColor, for: .normal)
            button.backgroundColor = .clear
        }
    }
    
    @objc
    private func weekDayClicked(btn: UIButton){
        let names = getWeekdayNames()
        let day = names[btn.tag]
        self.delegate?.didTapDay(with: day, selected: !btn.isSelected)
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
