//
//  HMSegmentedControl_CodeEagle.swift
//  Pods
//
//  Created by LawLincoln on 16/3/16.
//
//

import UIKit
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

var iOSTen: Bool {
    return ProcessInfo().isOperatingSystemAtLeast(OperatingSystemVersion(majorVersion: 10, minorVersion: 0, patchVersion: 0))
}
//MARK:- protocol
public protocol HMSegmentTitleConvertible {
	var title: (string: String?, attributedString: NSAttributedString?) { get }
}
//MARK:- extension
extension String: HMSegmentTitleConvertible {
	public var title: (string: String?, attributedString: NSAttributedString?) {
		return (self, nil)
	}
}

extension NSAttributedString: HMSegmentTitleConvertible {
	public var title: (string: String?, attributedString: NSAttributedString?) {
		return (nil, self)
	}
}

extension Array {
	subscript(safe index: Int) -> Element? {
		return indices.contains(index) ? self[index]: nil
	}
}

//MARK:- TypeAlias
public typealias IndexChangeBlock = (UInt) -> Void
public typealias HMTitleFormatterBlock = (_ segmentedControl: HMSegmentedControl_CodeEagle, _ title: String, _ index: Int, _ selected: Bool) -> NSAttributedString
//MARK:- Enum
//MARK: HMSegmentedControlSelectionStyle
public enum HMSegmentedControlSelectionStyle {
	case textWidthStripe, fullWidthStripe, box, arrow
}
//MARK: HMSegmentedControlSelectionIndicatorLocation
public enum HMSegmentedControlSelectionIndicatorLocation {
	case up, down, none
}
//MARK: HMSegmentedControlSegmentWidthStyle
public enum HMSegmentedControlSegmentWidthStyle {
	case fixed, dynamic
}
//MARK: HMSegmentedControlBorderType
public enum HMSegmentedControlBorderType {
	case none
	case top
	case left
	case bottom
	case right
}
//MARK: HMSegmentedControlType
public enum HMSegmentedControlType {
	case text, images, textImages
}

//MARK: HMSegmentedControlIndex
private enum HMSegmentedControlIndex: Int {
	case noSegment = -1
}

//MARK:- HMSegmentedControl_CodeEagle
open class HMSegmentedControl_CodeEagle: UIControl {

	// MARK:- Public
	open var sectionTitles: [HMSegmentTitleConvertible]? {
		didSet {
			setNeedsLayout()
		}
	}

	open var sectionImages: [UIImage]? {
		didSet {
			setNeedsLayout()
		}
	}

	open var sectionSelectedImages: [UIImage]? {
		didSet {
			setNeedsLayout()
		}
	}

	/**
	 Provide a block to be executed when selected index is changed.

	 Alternativly, you could use `addTarget:action:forControlEvents:`
	 */
	open var indexChangeBlock: IndexChangeBlock?

	/**
	 Used to apply custom text styling to titles when set.

	 When this block is set, no additional styling is applied to the `NSAttributedString` object returned from this block.
	 */
	open var titleFormatter: HMTitleFormatterBlock?

	/**
	 Text attributes to apply to item title text.
	 */
	open dynamic var titleTextAttributes: [String: NSObject]?

	/*
	 Text attributes to apply to selected item title text.

	 Attributes not set in this dictionary are inherited from `titleTextAttributes`.
	 */
	open dynamic var selectedTitleTextAttributes: [String: NSObject]?

	/**
	 Color for the selection indicator stripe/box

	 Default is `R:52, G:181, B:229`
	 */
	open dynamic lazy var selectionIndicatorColor = UIColor(red: 52, green: 181, blue: 229, alpha: 1)

	/**
	 Color for the vertical divider between segments.

	 Default is `[UIColor blackColor]`
	 */
	open dynamic lazy var verticalDividerColor = UIColor.black

	/**
	 Opacity for the seletion indicator box.

	 Default is `0.2f`
	 */
	open var selectionIndicatorBoxOpacity: Float = 0.2 {
		didSet {
			selectionIndicatorBoxLayer.opacity = selectionIndicatorBoxOpacity
		}
	}

	/**
	 Width the vertical divider between segments that is added when `verticalDividerEnabled` is set to YES.

	 Default is `1.0f`
	 */
	open lazy var verticalDividerWidth: CGFloat = 1

	/**
	 Specifies the style of the control

	 Default is `.Text`
	 */
	open lazy var type: HMSegmentedControlType = .text

	/**
	 Specifies the style of the selection indicator.

	 Default is `HMSegmentedControlSelectionStyleTextWidthStripe`
	 */
	open lazy var selectionStyle: HMSegmentedControlSelectionStyle = .textWidthStripe

	/**
	 Specifies the style of the segment's width.

	 Default is `.Fixed`
	 */
	open var segmentWidthStyle: HMSegmentedControlSegmentWidthStyle = .fixed {
		didSet {
			if type == .images && segmentWidthStyle != .fixed {
				segmentWidthStyle = .fixed
			}
		}
	}

	/**
	 Specifies the width of gap when segmentWidthStyle == .Dynamic.

	 Default is 10
	 */
	open var segmentWidthStyleDynamicGap: CGFloat = 30 {
		didSet {
			if segmentWidthStyle == .dynamic {
				setNeedsDisplay()
			}
		}
	}
	/**
	 Specifies the padding width of header and footer spacing when segmentWidthStyle == .Dynamic.

	 Default is 20
	 */
	open var segmentWidthStyleDynamicHeaderFooterPading: CGFloat = 20 {
		didSet {
			if segmentWidthStyle == .dynamic {
				setNeedsDisplay()
			}
		}
	}

	/**
	 Specifies the location of the selection indicator.

	 Default is `HMSegmentedControlSelectionIndicatorLocationUp`
	 */
	open var selectionIndicatorLocation: HMSegmentedControlSelectionIndicatorLocation = .up {
		didSet {
			if selectionIndicatorLocation == .none {
				selectionIndicatorHeight = 0
			}
		}
	}

	/*
	 Specifies the border type.

	 Default is `HMSegmentedControlBorderTypeNone`
	 */
	open var borderType: [HMSegmentedControlBorderType] = [.none] {
		didSet {
			setNeedsDisplay()
		}
	}

	/**
	 Specifies the border color.

	 Default is `[UIColor blackColor]`
	 */
	open lazy var borderColor = UIColor.black

	/**
	 Specifies the border width.

	 Default is `1.0f`
	 */
	open lazy var borderWidth: CGFloat = 1

	/**
	 Default is YES. Set to NO to deny scrolling by dragging the scrollView by the user.
	 */
	open lazy var userDraggable = true

	/**
	 Default is YES. Set to NO to deny any touch events by the user.
	 */
	open lazy var touchEnabled = true

	/**
	 Default is NO. Set to YES to show a vertical divider between the segments.
	 */
	open lazy var verticalDividerEnabled = false

	/**
	 Index of the currently selected segment.
	 */
	open var selectedSegmentIndex: Int = 0

	/**
	 Height of the selection indicator. Only effective when `HMSegmentedControlSelectionStyle` is either `HMSegmentedControlSelectionStyleTextWidthStripe` or `HMSegmentedControlSelectionStyleFullWidthStripe`.

	 Default is 5.0
	 */
	open lazy var selectionIndicatorHeight: CGFloat = 5

	/**
	 Edge insets for the selection indicator.
	 NOTE: This does not affect the bounding box of HMSegmentedControlSelectionStyleBox

	 When HMSegmentedControlSelectionIndicatorLocationUp is selected, bottom edge insets are not used

	 When HMSegmentedControlSelectionIndicatorLocationDown is selected, top edge insets are not used

	 Defaults are top: 0.0f
	 left: 0.0f
	 bottom: 0.0f
	 right: 0.0f
	 */
	open lazy var selectionIndicatorEdgeInsets = UIEdgeInsets.zero

	/**
	 Inset left and right edges of segments.

	 Default is UIEdgeInsetsMake(0, 5, 0, 5)
	 */
	open lazy var segmentEdgeInset = UIEdgeInsetsMake(0, 5, 0, 5)

	/**
	 Default is YES. Set to NO to disable animation during user selection.
	 */
	open lazy var shouldAnimateUserSelection = true

	open lazy var BadgeRadiu: CGFloat = 6

	open lazy var bottomBorder = false

	deinit {
		self.removeObserver(self, forKeyPath: "frame")
	}

	override init(frame: CGRect) {
		super.init(frame: frame)
		commonInit()
	}

	public required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		commonInit()
	}
    
    open override func awakeFromNib() {
        super.awakeFromNib()
        segmentWidth = 0
        commonInit()
    }

	// MARK:- Private
	fileprivate lazy var selectionIndicatorStripLayer = CALayer()
	fileprivate lazy var selectionIndicatorBoxLayer = CALayer()
	fileprivate lazy var selectionIndicatorArrowLayer = CALayer()
	fileprivate lazy var segmentWidth: CGFloat = 1
	fileprivate lazy var segmentWidthsArray: [CGFloat] = []
	fileprivate lazy var scrollView: HMScrollView = HMScrollView()
	fileprivate lazy var badgeMap: [String: CALayer] = [:]
	fileprivate lazy var offsetXForCenterAllControl: CGFloat = 0
}

//MARK:- Init
public extension HMSegmentedControl_CodeEagle {

	convenience init(sectionTitles titles: [HMSegmentTitleConvertible]) {
		self.init(frame: CGRect.zero)
		sectionTitles = titles
	}

	convenience init(sectionImages off: [UIImage], sectionSelectedImages on: [UIImage]) {
		self.init(frame: CGRect.zero)
		sectionImages = off
		sectionSelectedImages = on
		type = .images
	}

	convenience init(sectionTitles titles: [HMSegmentTitleConvertible], sectionImages off: [UIImage], sectionSelectedImages on: [UIImage]) {
		assert(off.count == titles.count, ":\(#function): Images bounds (\(off.count)) Dont match Title bounds (\(titles.count))")
		self.init(frame: CGRect.zero)
		sectionTitles = titles
		sectionImages = off
		sectionSelectedImages = on
		type = .textImages
	}

	

	fileprivate func commonInit() {
		scrollView.scrollsToTop = false
		scrollView.showsHorizontalScrollIndicator = false
		scrollView.showsVerticalScrollIndicator = false
		scrollView.alwaysBounceHorizontal = true
		addSubview(scrollView)

		backgroundColor = UIColor.white
		isOpaque = false

		selectionIndicatorBoxLayer.opacity = selectionIndicatorBoxOpacity
		selectionIndicatorBoxLayer.borderWidth = 1
		contentMode = .redraw
		addObserver(self, forKeyPath: "frame", options: .new, context: nil)
	}
}

extension HMSegmentedControl_CodeEagle {

	open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
		if keyPath == "frame" {
			updateSegmentsRects()
		}
	}

	open override func layoutSubviews() {
		super.layoutSubviews()
		updateSegmentsRects()
	}
}
//MARK:- Drawing
private extension HMSegmentedControl_CodeEagle {

	func measureTitleAtIndex(_ index: Int) -> CGSize {
		var size = CGSize.zero

		guard let titles = sectionTitles else { return size }
		if index < 0 || index >= titles.count { return size }
		let data = titles[index].title
		let selected = index == selectedSegmentIndex

		var attributeTitle = data.attributedString
		if attributeTitle == nil {
			guard let titleString = data.string else { return size }
			if let formator = titleFormatter {
				attributeTitle = formator(self, titleString, index, selected)
			} else {
				let attribute = selected ? resultingSelectedTitleTextAttributes : resultingTitleTextAttributes
				attributeTitle = NSAttributedString(string: titleString, attributes: attribute)
			}
		}
		size = attributeTitle?.size() ?? CGSize.zero
		return CGRect(origin: CGPoint.zero, size: size).integral.size
	}

	func attributedTitleAtIndex(_ index: Int) -> NSAttributedString? {
		guard let titles = sectionTitles else { return nil }
		if index >= titles.count || index < 0 { return nil }
		let title = titles[index].title
		let selected = index == selectedSegmentIndex

		if let attributedString = title.attributedString { return attributedString }
		guard let titleString = title.string else { return nil }
		var attributeTitle = title.attributedString
		if let formator = titleFormatter {
			attributeTitle = formator(self, titleString, index, selected)
		} else {
			var titleAttrs: [String: AnyObject] = selected ? resultingSelectedTitleTextAttributes : resultingTitleTextAttributes
			if let titleColor = titleAttrs[NSForegroundColorAttributeName] as? UIColor {
				titleAttrs[NSForegroundColorAttributeName] = titleColor.cgColor
			}
			attributeTitle = NSAttributedString(string: titleString, attributes: titleAttrs)
		}
		return attributeTitle
	}

	func addBackgroundAndBorderLayerWithRect(_ fullRect: CGRect) {
		// Background layer
		let backgroundLayer = CALayer()
		backgroundLayer.frame = fullRect
		scrollView.layer.insertSublayer(backgroundLayer, at: 0)

		// Border layer
		let width = fullRect.size.width
		let height = fullRect.size.height
		let total = [
			HMSegmentedControlBorderType.top: CGRect(x: 0, y: 0, width: width, height: borderWidth),
			HMSegmentedControlBorderType.left: CGRect(x: 0, y: 0, width: borderWidth, height: height),
			HMSegmentedControlBorderType.bottom: CGRect(x: 0, y: height - borderWidth, width: width, height: borderWidth),
			HMSegmentedControlBorderType.right: CGRect(x: width - borderWidth, y: 0, width: borderWidth, height: height)
		]
		for (type, frame) in total {
			if !borderType.contains(type) { continue }
			let borderLayer = CALayer()
			borderLayer.frame = frame
			borderLayer.backgroundColor = borderColor.cgColor
			backgroundLayer.addSublayer(borderLayer)
		}
	}

	func setArrowFrame() {
		selectionIndicatorArrowLayer.frame = frameForSelectionIndicator()

		selectionIndicatorArrowLayer.mask = nil

		let arrowPath = UIBezierPath()

		var p1 = CGPoint.zero
		var p2 = CGPoint.zero
		var p3 = CGPoint.zero

		if selectionIndicatorLocation == .down {
			p1 = CGPoint(x: selectionIndicatorArrowLayer.bounds.size.width / 2, y: 0)
			p2 = CGPoint(x: 0, y: selectionIndicatorArrowLayer.bounds.size.height)
			p3 = CGPoint(x: selectionIndicatorArrowLayer.bounds.size.width, y: selectionIndicatorArrowLayer.bounds.size.height)
		}

		if selectionIndicatorLocation == .up {
			p1 = CGPoint(x: selectionIndicatorArrowLayer.bounds.size.width / 2, y: selectionIndicatorArrowLayer.bounds.size.height)
			p2 = CGPoint(x: selectionIndicatorArrowLayer.bounds.size.width, y: 0)
			p3 = CGPoint(x: 0, y: 0)
		}
		arrowPath.move(to: p1)
		arrowPath.addLine(to: p2)
		arrowPath.addLine(to: p3)
		arrowPath.close()

		let maskLayer = CAShapeLayer()
		maskLayer.frame = selectionIndicatorArrowLayer.bounds
		maskLayer.path = arrowPath.cgPath
		selectionIndicatorArrowLayer.mask = maskLayer
	}

	func frameForSelectionIndicator() -> CGRect {
		var indicatorYOffset: CGFloat = 0

		if selectionIndicatorLocation == .down {
			indicatorYOffset = bounds.size.height - selectionIndicatorHeight + selectionIndicatorEdgeInsets.bottom
		}

		if selectionIndicatorLocation == .up {
			indicatorYOffset = selectionIndicatorEdgeInsets.top
		}

		var sectionWidth: CGFloat = 0
		let index = selectedSegmentIndex
		if type == .text {
			sectionWidth = measureTitleAtIndex(index).width
		} else if type == .images {
			let idx = Int(index)
			if idx < sectionImages?.count {
				let sectionImage = sectionImages?[idx]
				sectionWidth = sectionImage?.size.width ?? 0
			}
		} else if type == .textImages {
			let stringWidth = measureTitleAtIndex(index).width
			var imageWidth: CGFloat = 0
			let idx = Int(index)
			if idx < sectionImages?.count {
				let sectionImage = sectionImages?[idx]
				imageWidth = sectionImage?.size.width ?? 0
			}
			sectionWidth = max(stringWidth, imageWidth)
		}

		let floatIndex = CGFloat(index)
		if selectionStyle == .arrow {
			let widthToStartOfSelectedIndex = (segmentWidth * floatIndex)
			let widthToEndOfSelectedSegment = widthToStartOfSelectedIndex + segmentWidth
			let x = widthToStartOfSelectedIndex + ((widthToEndOfSelectedSegment - widthToStartOfSelectedIndex) / 2) - (selectionIndicatorHeight / 2)
			return CGRect(x: x - (selectionIndicatorHeight / 2), y: indicatorYOffset, width: selectionIndicatorHeight * 2, height: selectionIndicatorHeight)
		} else {
			if selectionStyle == .textWidthStripe &&
			sectionWidth <= segmentWidth &&
			segmentWidthStyle != .dynamic {

				let widthToStartOfSelectedIndex = (segmentWidth * floatIndex)
				let widthToEndOfSelectedSegment = widthToStartOfSelectedIndex + segmentWidth
				let x = ((widthToEndOfSelectedSegment - widthToStartOfSelectedIndex) / 2) + (widthToStartOfSelectedIndex - sectionWidth / 2) + offsetXForCenterAllControl
				return CGRect(x: x + selectionIndicatorEdgeInsets.left, y: indicatorYOffset, width: sectionWidth - selectionIndicatorEdgeInsets.right, height: selectionIndicatorHeight);
			} else {
				if segmentWidthStyle == .dynamic {

					let x = selectedSegmentOffset + selectionIndicatorEdgeInsets.left + offsetXForCenterAllControl
					let y = indicatorYOffset
					let idx = Int(index)
					let width = segmentWidthsArray[idx] - selectionIndicatorEdgeInsets.right
					let height = selectionIndicatorHeight + selectionIndicatorEdgeInsets.bottom
					return CGRect(x: x, y: y, width: width, height: height)
				}
				return CGRect(
					x: (segmentWidth + selectionIndicatorEdgeInsets.left) * floatIndex + offsetXForCenterAllControl,
					y: indicatorYOffset,
					width: segmentWidth - selectionIndicatorEdgeInsets.right,
					height: selectionIndicatorHeight)
			}
		}
	}

	func frameForFillerSelectionIndicator() -> CGRect {
		if segmentWidthStyle == .dynamic {
			let idx = Int(UInt(selectedSegmentIndex))
			var width: CGFloat = 0
			if idx < segmentWidthsArray.count {
				width = segmentWidthsArray[idx]
			}
			return CGRect(x: selectedSegmentOffset, y: 0, width: width, height: frame.height)
		}
		return CGRect(x: segmentWidth * CGFloat(selectedSegmentIndex), y: 0, width: segmentWidth, height: self.frame.height)
	}

	func updateSegmentsRects() {

		scrollView.contentInset = UIEdgeInsets.zero
		scrollView.frame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)

		if sectionCount > 0 {
			segmentWidth = frame.size.width / CGFloat(sectionCount)
		}

		if let titles = sectionTitles , type == .text {
			var mutableSegmentWidths: [CGFloat] = []
			for index in 0 ..< titles.count {
				let stringWidth = measureTitleAtIndex(index).width + segmentEdgeInset.left + segmentEdgeInset.right
				if segmentWidthStyle == .fixed {
					segmentWidth = max(stringWidth, segmentWidth)
				} else if segmentWidthStyle == .dynamic {
					mutableSegmentWidths.append(stringWidth)
				}
			}
			if mutableSegmentWidths.count > 0 {
				segmentWidthsArray = mutableSegmentWidths
			}
		} else if let images = sectionImages , type == .images {
			for item in images {
				let imageWidth = item.size.width + segmentEdgeInset.left + segmentEdgeInset.right
				segmentWidth = max(imageWidth, segmentWidth)
			}
		} else if let titles = sectionTitles, let images = sectionImages , type == .textImages {
			var mutableSegmentWidths: [CGFloat] = []
			for index in 0 ..< titles.count {
				let stringWidth = measureTitleAtIndex(index).width + segmentEdgeInset.left + segmentEdgeInset.right
				let imageWidth = images[index].size.width + segmentEdgeInset.left + segmentEdgeInset.right

				if segmentWidthStyle == .fixed {
					segmentWidth = max(stringWidth, segmentWidth)
				} else if segmentWidthStyle == .dynamic {
					let width = max(imageWidth, stringWidth)
					mutableSegmentWidths.append(width)
				}
			}
			if mutableSegmentWidths.count > 0 {
				segmentWidthsArray = mutableSegmentWidths
			}
		}
		scrollView.isScrollEnabled = userDraggable
		scrollView.contentSize = CGSize(width: totalSegmentedControlWidth, height: frame.size.height)
	}

	var sectionCount: UInt {
		var count: UInt = 0
		if type == .text {
			let acount = sectionTitles?.count ?? 0
			count = UInt(acount)
		} else if type == .images || type == .textImages {
			let acount = sectionImages?.count ?? 0
			count = UInt(acount)
		}
		return count
	}

	var selectedSegmentOffset: CGFloat {
		var offset: CGFloat = 0
		var i = 0
		for width in segmentWidthsArray {
			if selectedSegmentIndex == i { break }
			offset += width
			if segmentWidthStyle == .dynamic {
				offset += segmentWidthStyleDynamicGap
			}
			i += 1
		}
		return offset
	}
}
//MARK:- DrawRect
extension HMSegmentedControl_CodeEagle {

	open override func draw(_ rect: CGRect) {
		backgroundColor?.set()
		UIRectFill(bounds)
		updateOffsetXForCEnterAllControl()

		selectionIndicatorArrowLayer.backgroundColor = selectionIndicatorColor.cgColor
		selectionIndicatorStripLayer.backgroundColor = selectionIndicatorColor.cgColor
		selectionIndicatorBoxLayer.backgroundColor = selectionIndicatorColor.cgColor
		selectionIndicatorBoxLayer.borderColor = selectionIndicatorColor.cgColor

		scrollView.layer.backgroundColor = backgroundColor?.cgColor
		scrollView.layer.sublayers = nil

		let oldRect = rect
		switch type {
		case .text: drawText(oldRect)
		case .images: drawImage()
		case .textImages: drawTextImage()
		}
		addBadge()
		addSelectionIndicators()
		addSeperator()
	}

	fileprivate func updateOffsetXForCEnterAllControl() {
		let totalWidth = totalSegmentedControlWidth
		var offsetX: CGFloat = 0

		if totalWidth < bounds.width {
			offsetX = (bounds.width - totalWidth) / 2
		}

		if segmentWidthStyle == .dynamic {
			offsetX += segmentWidthStyleDynamicHeaderFooterPading
		}

		offsetXForCenterAllControl = offsetX
	}

	fileprivate func drawText(_ oldRect: CGRect) {
		guard let titles = sectionTitles else { return }

		for idx in 0 ..< titles.count {
			let fIndex = CGFloat(idx)
			let size = measureTitleAtIndex(idx)
			let stringWidth = size.width
			let stringHeight = size.height
			var rectDiv = CGRect.zero
			var fullRect = CGRect.zero

			let locationUp: CGFloat = selectionIndicatorLocation == .up ? 1 : 0
			let selectionStyleNotBox: CGFloat = selectionStyle != .box ? 1 : 0
			let toRound = (frame.height - selectionStyleNotBox * selectionIndicatorHeight) / 2 - stringHeight / 2 + selectionIndicatorHeight * locationUp
			var y = round(toRound)

			var rect = CGRect.zero
			if segmentWidthStyle == .fixed {
				var x = segmentWidth * fIndex + (segmentWidth - stringWidth) / 2 + offsetXForCenterAllControl
				rect = CGRect(x: x, y: y, width: stringWidth, height: stringHeight)
				x = segmentWidth * fIndex - verticalDividerWidth / 2
				y = selectionIndicatorHeight * 2
				let height = frame.size.height - selectionIndicatorHeight * 4
				rectDiv = CGRect(x: x, y: y, width: verticalDividerWidth, height: height)
				fullRect = CGRect(x: segmentWidth * fIndex, y: 0, width: segmentWidth, height: oldRect.size.height)
			} else if segmentWidthStyle == .dynamic {
				var xOffset: CGFloat = offsetXForCenterAllControl

				for (i, width) in segmentWidthsArray.enumerated() {
					if (idx == i) { break }
					xOffset = xOffset + width + segmentWidthStyleDynamicGap
				}
				let widthForIndex: CGFloat = (segmentWidthsArray[safe: idx] ?? 0)
				rect = CGRect(x: xOffset, y: y, width: widthForIndex, height: stringHeight)
				fullRect = CGRect(x: xOffset, y: 0, width: widthForIndex, height: oldRect.size.height)
				rectDiv = CGRect(
					x: xOffset - verticalDividerWidth / 2,
					y: selectionIndicatorHeight * 2,
					width: verticalDividerWidth,
					height: frame.size.height - selectionIndicatorHeight * 4)
			}

			// Fix rect position/size to avoid blurry labels
			rect = CGRect(x: ceil(rect.origin.x), y: ceil(rect.origin.y), width: ceil(rect.size.width), height: ceil(rect.size.height))
			let text = attributedTitleAtIndex(idx)
			var titleLayer = CATextLayer()

			if backgroundColor != nil && backgroundColor != UIColor.clear {
				let layer = OpaqueTextLayer()
				layer.setBackgroundC(backgroundColor)
				titleLayer = layer
				titleLayer.isOpaque = true
			}
			titleLayer.frame = rect
			titleLayer.alignmentMode = kCAAlignmentCenter
            titleLayer.truncationMode = iOSTen ? kCATruncationNone : kCATruncationEnd
            titleLayer.string = text
			titleLayer.contentsScale = UIScreen.main.scale
			scrollView.layer.addSublayer(titleLayer)

			// Badge
			if let title = text?.string {
				let dot = badgeDotForTitle(title)
				let offsetX: CGFloat = segmentWidthStyle == .dynamic ? BadgeRadiu : 0
				let offsetY: CGFloat = segmentWidthStyle == .dynamic ? BadgeRadiu / 2: 0
				let centerPoint = CGPoint(x: titleLayer.frame.maxX - offsetX, y: titleLayer.frame.minY - offsetY)
				dot?.frame = CGRect(x: centerPoint.x, y: centerPoint.y, width: BadgeRadiu, height: BadgeRadiu);
			}

			// Vertical Divider
			addVerticalDivider(rectDiv, idx: idx)
			addBackgroundAndBorderLayerWithRect(fullRect)
		}
	}

	fileprivate func drawImage() {
		guard let value = sectionImages else { return }
		for (idx, iconImage) in value.enumerated() {
			let fIdx = CGFloat(idx)
			let icon = iconImage
			let imageWidth = icon.size.width
			let imageHeight = icon.size.height
			let y = round(frame.height - selectionIndicatorHeight) / 2 - imageHeight / 2 + ((selectionIndicatorLocation == .up) ? selectionIndicatorHeight : 0)
			let x = segmentWidth * fIdx + (segmentWidth - imageWidth) / 2.0
			let rect = CGRect(x: x, y: y, width: imageWidth, height: imageHeight)

			let imageLayer = CALayer()
			imageLayer.frame = rect
			imageLayer.contents = icon.cgImage;
			if selectedSegmentIndex == idx {
				imageLayer.contents = sectionSelectedImages?[safe: idx]?.cgImage ?? icon.cgImage
			}
			scrollView.layer.addSublayer(imageLayer)
			// Vertical Divider
			let rectDiv = CGRect(x: (segmentWidth * fIdx) - (verticalDividerWidth / 2), y: selectionIndicatorHeight * 2, width: verticalDividerWidth, height: self.frame.size.height - (selectionIndicatorHeight * 4))
			addVerticalDivider(rectDiv, idx: idx)
			addBackgroundAndBorderLayerWithRect(rect)
		}
	}

	fileprivate func drawTextImage() {
		guard let value = sectionImages else { return }

		for (idx, iconImage) in value.enumerated() {
			let fIdx = CGFloat(idx)
			let icon = iconImage
			let imageWidth = icon.size.width
			let imageHeight = icon.size.height
			let stringHeight = measureTitleAtIndex(idx).height
			let yOffset = round(((frame.height - selectionIndicatorHeight) / 2) - (stringHeight / 2))
			var imageXOffset = segmentEdgeInset.left // Start with edge inset
			var textXOffset = segmentEdgeInset.left
			var textWidth: CGFloat = 0

			if segmentWidthStyle == .fixed {
				imageXOffset = segmentWidth * fIdx + segmentWidth / 2 - imageWidth / 2
				textXOffset = segmentWidth * fIdx
				textWidth = segmentWidth
			} else if segmentWidthStyle == .dynamic {
				// When we are drawing dynamic widths, we need to loop the widths array to calculate the xOffset
				var xOffset: CGFloat = 0
				for (i, width) in segmentWidthsArray.enumerated() {
					if idx == i { break }
					xOffset += width
				}
				let width = segmentWidthsArray[safe: idx] ?? 0
				imageXOffset = xOffset + width / 2 - (imageWidth / 2)
				textXOffset = xOffset
				textWidth = width
			}

			let imageYOffset = round((frame.height - selectionIndicatorHeight) / 2)
			let imageRect = CGRect(x: imageXOffset, y: imageYOffset, width: imageWidth, height: imageHeight)

			let imageLayer = CALayer()
			imageLayer.frame = imageRect
			imageLayer.contents = icon.cgImage
			if selectedSegmentIndex == idx {
				imageLayer.contents = sectionSelectedImages?[safe: idx]?.cgImage ?? icon.cgImage
			}
			scrollView.layer.addSublayer(imageLayer)

			// Fix rect position/size to avoid blurry labels
			let textRect = CGRect(x: ceil(textXOffset), y: ceil(yOffset), width: ceil(textWidth), height: ceil(stringHeight))
			let text = attributedTitleAtIndex(idx)
			let titleLayer = CATextLayer()
			titleLayer.frame = textRect
			titleLayer.alignmentMode = kCAAlignmentCenter
			titleLayer.string = text
			titleLayer.truncationMode = kCATruncationEnd
			titleLayer.contentsScale = UIScreen.main.scale
			scrollView.layer.addSublayer(titleLayer)

			// Badge
			if let title = text?.string {
				let dot = badgeDotForTitle(title)
				let centerPoint = CGPoint(x: titleLayer.frame.maxX, y: titleLayer.frame.minY)
				dot?.frame = CGRect(x: centerPoint.x, y: centerPoint.y, width: BadgeRadiu, height: BadgeRadiu);
			}
			addBackgroundAndBorderLayerWithRect(imageRect)
		}
	}

	fileprivate func addVerticalDivider(_ rect: CGRect, idx: Int) {
		if verticalDividerEnabled && idx > 0 {
			let verticalDividerLayer = CALayer()
			verticalDividerLayer.frame = rect
			verticalDividerLayer.backgroundColor = self.verticalDividerColor.cgColor
			scrollView.layer.addSublayer(verticalDividerLayer)
		}
	}

	fileprivate func addBadge() {
		for key in badgeMap.keys {
			if let layer = self.badgeMap[key] {
				scrollView.layer.addSublayer(layer)
			}
		}
	}

	fileprivate func addSelectionIndicators() {
		if selectedSegmentIndex == HMSegmentedControlIndex.noSegment.rawValue { return }
		if selectionStyle == .arrow {
			if selectionIndicatorArrowLayer.superlayer == nil {
				setArrowFrame()
				scrollView.layer.addSublayer(selectionIndicatorArrowLayer)
			}
		} else {
			if selectionIndicatorStripLayer.superlayer == nil {
				selectionIndicatorStripLayer.frame = frameForSelectionIndicator()
				scrollView.layer.addSublayer(selectionIndicatorStripLayer)

				if selectionStyle == .box && selectionIndicatorBoxLayer.superlayer == nil {
					self.selectionIndicatorBoxLayer.frame = frameForFillerSelectionIndicator()
					scrollView.layer.insertSublayer(selectionIndicatorBoxLayer, at: 0)
				}
			}
		}
	}

	fileprivate func addSeperator() {
		if bottomBorder {
			let line = CALayer()
			line.frame = CGRect(x: 0, y: frame.height - 0.5, width: frame.width, height: 0.5)
			line.backgroundColor = UIColor.lightGray.cgColor
			layer.addSublayer(line)
		}
	}

	open override func willMove(toSuperview newSuperview: UIView?) {
		if newSuperview == nil { return }
		if sectionTitles != nil || sectionImages != nil {
			updateSegmentsRects()
		}
	}
}
//MARK:- Touch
extension HMSegmentedControl_CodeEagle {

	open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
		guard let location = touches.first?.location(in: self) else { return }
		if !bounds.contains(location) { return }
		var segment = 0
		if segmentWidthStyle == .fixed {
			segment = Int((location.x + scrollView.contentOffset.x - offsetXForCenterAllControl) / segmentWidth)
		} else if segmentWidthStyle == .dynamic {
			var widthLeft = location.x + scrollView.contentOffset.x - offsetXForCenterAllControl
			for width in segmentWidthsArray {
				widthLeft -= width + segmentWidthStyleDynamicGap
				if widthLeft <= 0 { break }
				segment += 1
			}
		}

		var sectionsCount = 0

		if type == .images {
			sectionsCount = sectionImages?.count ?? 0
		} else if type == .textImages || type == .text {
			sectionsCount = sectionTitles?.count ?? 0
		}
		if segment != selectedSegmentIndex && segment < sectionsCount {
			if touchEnabled {
				setSelectedSegmentIndex(segment, animated: shouldAnimateUserSelection, notify: true)
			}
		}
	}
}
//MARK:- Index Change
extension HMSegmentedControl_CodeEagle {

	public func setSelectedSegmentIndex(_ index: Int, animated: Bool = false, notify: Bool = false) {
		if selectedSegmentIndex == index { return }
		selectedSegmentIndex = index
		indexChange(animated, notify: notify)
	}

	func indexChange(_ animated: Bool = false, notify: Bool = false) {
		let index = selectedSegmentIndex
		setNeedsDisplay()

		if selectedSegmentIndex == HMSegmentedControlIndex.noSegment.rawValue {
			[selectionIndicatorArrowLayer, selectionIndicatorStripLayer, selectionIndicatorBoxLayer].forEach({ (layer) -> () in
				layer.removeFromSuperlayer()
			})
		} else {
			scrollToSelectedSegmentIndex(animated)

			if animated {
				// If the selected segment layer is not added to the super layer, that means no
				// index is currently selected, so add the layer then move it to the new
				// segment index without animating.
				if selectionStyle == .arrow {
					if selectionIndicatorArrowLayer.superlayer == nil {
						scrollView.layer.addSublayer(selectionIndicatorArrowLayer)
						setSelectedSegmentIndex(index, notify: true)
						return
					}
				} else {
					if selectionIndicatorStripLayer.superlayer == nil {
						scrollView.layer.addSublayer(selectionIndicatorStripLayer)

						if selectionStyle == .box && selectionIndicatorBoxLayer.superlayer == nil {
							scrollView.layer.insertSublayer(selectionIndicatorBoxLayer, at: 0)
						}
						setSelectedSegmentIndex(index, notify: true)
						return
					}
				}

				// Restore CALayer animations
				selectionIndicatorArrowLayer.actions = nil
				selectionIndicatorStripLayer.actions = nil
				selectionIndicatorBoxLayer.actions = nil

				// Animate to new position
				CATransaction.begin()
				CATransaction.setCompletionBlock({
					if notify {
						self.notifyForSegmentChangeToIndex(UInt(index))
					}
				})
				CATransaction.setAnimationDuration(0.15)
				CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(controlPoints: 0.4, 0.1, 0.3, 1.2))
				setArrowFrame()
				selectionIndicatorArrowLayer.frame = frameForSelectionIndicator()
				selectionIndicatorStripLayer.frame = frameForSelectionIndicator()
				selectionIndicatorBoxLayer.frame = frameForFillerSelectionIndicator()
				CATransaction.commit()
			} else {
				// Disable CALayer animations
				let animations = ["position": NSNull(), "bounds": NSNull()]
				selectionIndicatorArrowLayer.actions = animations

				selectionIndicatorArrowLayer.frame = frameForSelectionIndicator()
				selectionIndicatorStripLayer.actions = animations
				selectionIndicatorStripLayer.frame = frameForSelectionIndicator()
				selectionIndicatorBoxLayer.actions = animations
				selectionIndicatorBoxLayer.frame = frameForFillerSelectionIndicator()
				setArrowFrame()

				if notify {
					notifyForSegmentChangeToIndex(UInt(index))
				}
			}
		}
	}

	func notifyForSegmentChangeToIndex(_ index: UInt) {
		if superview != nil {
			sendActions(for: UIControlEvents.valueChanged)
		}
		indexChangeBlock?(index)
	}
}
//MARK:- Scrolling
private extension HMSegmentedControl_CodeEagle {

	var totalSegmentedControlWidth: CGFloat {
		if segmentWidthStyle == .fixed {
			return segmentWidth * CGFloat(sectionCount)
		} else {
			return segmentWidthsArray.reduce(0, +) + CGFloat(sectionCount - 1) * segmentWidthStyleDynamicGap + segmentWidthStyleDynamicHeaderFooterPading * 2
		}
	}

	func scrollToSelectedSegmentIndex(_ animated: Bool) {
		var rectForSelectedIndex = CGRect.zero
		var _selectedSegmentOffset: CGFloat = 0
		if segmentWidthStyle == .fixed {
			rectForSelectedIndex = CGRect(
				x: segmentWidth * CGFloat(selectedSegmentIndex),
				y: 0,
				width: segmentWidth,
				height: frame.size.height)

			_selectedSegmentOffset = (frame.width / 2) - (segmentWidth / 2)
		} else if segmentWidthStyle == .dynamic {
			let offsetter = selectedSegmentOffset
			var width: CGFloat = 0
			if selectedSegmentIndex < segmentWidthsArray.count {
				width = segmentWidthsArray[selectedSegmentIndex]
			}
			rectForSelectedIndex = CGRect(x: offsetter, y: 0, width: width, height: frame.size.height)
			_selectedSegmentOffset = (self.frame.width / 2) - (width / 2)
		}

		var rectToScrollTo = rectForSelectedIndex
		rectToScrollTo.origin.x -= _selectedSegmentOffset
		rectToScrollTo.size.width += _selectedSegmentOffset * 2
		scrollView.scrollRectToVisible(rectToScrollTo, animated: animated)
	}
}

//MARK:- Styling Support
private extension HMSegmentedControl_CodeEagle {

	var resultingTitleTextAttributes: [String: NSObject] {
		var defaults = [
			NSFontAttributeName: UIFont.systemFont(ofSize: 19),
			NSForegroundColorAttributeName: UIColor.black
		]
		if let attribute = titleTextAttributes {
			for key in attribute.keys {
				defaults[key] = attribute[key]
			}
		}
		return defaults
	}

	var resultingSelectedTitleTextAttributes: [String: NSObject] {
		var resultingAttrs = resultingTitleTextAttributes
		if let attribute = selectedTitleTextAttributes {
			for key in attribute.keys {
				resultingAttrs[key] = attribute[key]
			}
		}
		return resultingAttrs
	}
}

//MARK:- Badge
extension HMSegmentedControl_CodeEagle {

	public func toggleMatchTitle(_ title: HMSegmentTitleConvertible?, hide: Bool) {
		guard let key = title?.title.string ?? title?.title.attributedString?.string else { return }
		hide ? removeBadgeForTitle(key) : addBadgeForTitle(key)
	}

	fileprivate func addBadgeForTitle(_ title: String) {
		var dot: CALayer! = badgeDotForTitle(title)
		if dot == nil {
			dot = CALayer()
			dot.backgroundColor = UIColor.red.cgColor
			dot.frame = CGRect(x: 0, y: 0, width: BadgeRadiu, height: BadgeRadiu)
			dot.cornerRadius = BadgeRadiu / 2
			dot.masksToBounds = true
		}
		dot?.isHidden = false
		badgeMap[title] = dot
		setNeedsDisplay()
	}

	fileprivate func removeBadgeForTitle(_ title: String) {
		let dot = badgeDotForTitle(title)
		dot?.removeFromSuperlayer()
		badgeMap.removeValue(forKey: title)
	}

	fileprivate func badgeDotForTitle(_ title: String) -> CALayer? {
		return badgeMap[title]
	}
}

//MARK:- HMScrollView
final private class HMScrollView: UIScrollView {

	override init(frame: CGRect) {
		super.init(frame: frame)
	}

	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}

	// MARK:- Touch
	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		if isDragging {
			super.touchesBegan(touches, with: event)
			return
		}
		next?.touchesBegan(touches, with: event)
	}

	override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
		if isDragging {
			super.touchesMoved(touches, with: event)
			return
		}
		next?.touchesMoved(touches, with: event)
	}

	override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
		if isDragging {
			super.touchesEnded(touches, with: event)
			return
		}
		next?.touchesEnded(touches, with: event)
	}
}

private final class OpaqueTextLayer: CATextLayer {

	override init() {
		super.init()
		initialize()
	}

	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		initialize()
	}

	override init(layer: Any) {
		super.init(layer: layer)
		initialize()
	}

	fileprivate func initialize() { contentsScale = UIScreen.main.scale }
	fileprivate var aBackgroundColor: UIColor! = UIColor.white

	func setBackgroundC(_ color: UIColor!) {
		if let c = color { aBackgroundColor = c }
		setNeedsDisplay()
	}

	override func draw(in ctx: CGContext) {
		UIGraphicsPushContext(ctx)
		ctx.setFillColor(aBackgroundColor.cgColor)
		ctx.fill(bounds)
		super.draw(in: ctx)
		UIGraphicsPopContext()
	}
}
