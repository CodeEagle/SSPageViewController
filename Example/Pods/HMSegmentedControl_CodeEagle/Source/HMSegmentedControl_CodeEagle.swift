//
//  HMSegmentedControl_CodeEagle.swift
//  Pods
//
//  Created by LawLincoln on 16/3/16.
//
//

import UIKit
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
public typealias HMTitleFormatterBlock = (segmentedControl: HMSegmentedControl_CodeEagle, title: String, index: Int, selected: Bool) -> NSAttributedString
//MARK:- Enum
//MARK: HMSegmentedControlSelectionStyle
public enum HMSegmentedControlSelectionStyle {
	case TextWidthStripe, FullWidthStripe, Box, Arrow
}
//MARK: HMSegmentedControlSelectionIndicatorLocation
public enum HMSegmentedControlSelectionIndicatorLocation {
	case Up, Down, None
}
//MARK: HMSegmentedControlSegmentWidthStyle
public enum HMSegmentedControlSegmentWidthStyle {
	case Fixed, Dynamic
}
//MARK: HMSegmentedControlBorderType
public enum HMSegmentedControlBorderType {
	case None
	case Top
	case Left
	case Bottom
	case Right
}
//MARK: HMSegmentedControlType
public enum HMSegmentedControlType {
	case Text, Images, TextImages
}

//MARK: HMSegmentedControlIndex
private enum HMSegmentedControlIndex: Int {
	case NoSegment = -1
}

//MARK:- HMSegmentedControl_CodeEagle
public class HMSegmentedControl_CodeEagle: UIControl {

	// MARK:- Public
	public var sectionTitles: [HMSegmentTitleConvertible]? {
		didSet {
			setNeedsLayout()
		}
	}

	public var sectionImages: [UIImage]? {
		didSet {
			setNeedsLayout()
		}
	}

	public var sectionSelectedImages: [UIImage]? {
		didSet {
			setNeedsLayout()
		}
	}

	/**
	 Provide a block to be executed when selected index is changed.

	 Alternativly, you could use `addTarget:action:forControlEvents:`
	 */
	public var indexChangeBlock: IndexChangeBlock?

	/**
	 Used to apply custom text styling to titles when set.

	 When this block is set, no additional styling is applied to the `NSAttributedString` object returned from this block.
	 */
	public var titleFormatter: HMTitleFormatterBlock?

	/**
	 Text attributes to apply to item title text.
	 */
	public dynamic var titleTextAttributes: [String: NSObject]?

	/*
	 Text attributes to apply to selected item title text.

	 Attributes not set in this dictionary are inherited from `titleTextAttributes`.
	 */
	public dynamic var selectedTitleTextAttributes: [String: NSObject]?

	/**
	 Color for the selection indicator stripe/box

	 Default is `R:52, G:181, B:229`
	 */
	public dynamic lazy var selectionIndicatorColor = UIColor(red: 52, green: 181, blue: 229, alpha: 1)

	/**
	 Color for the vertical divider between segments.

	 Default is `[UIColor blackColor]`
	 */
	public dynamic lazy var verticalDividerColor = UIColor.blackColor()

	/**
	 Opacity for the seletion indicator box.

	 Default is `0.2f`
	 */
	public var selectionIndicatorBoxOpacity: Float = 0.2 {
		didSet {
			selectionIndicatorBoxLayer.opacity = selectionIndicatorBoxOpacity
		}
	}

	/**
	 Width the vertical divider between segments that is added when `verticalDividerEnabled` is set to YES.

	 Default is `1.0f`
	 */
	public lazy var verticalDividerWidth: CGFloat = 1

	/**
	 Specifies the style of the control

	 Default is `.Text`
	 */
	public lazy var type: HMSegmentedControlType = .Text

	/**
	 Specifies the style of the selection indicator.

	 Default is `HMSegmentedControlSelectionStyleTextWidthStripe`
	 */
	public lazy var selectionStyle: HMSegmentedControlSelectionStyle = .TextWidthStripe

	/**
	 Specifies the style of the segment's width.

	 Default is `.Fixed`
	 */
	public var segmentWidthStyle: HMSegmentedControlSegmentWidthStyle = .Fixed {
		didSet {
			if type == .Images && segmentWidthStyle != .Fixed {
				segmentWidthStyle = .Fixed
			}
		}
	}

	/**
	 Specifies the width of gap when segmentWidthStyle == .Dynamic.

	 Default is 10
	 */
	public var segmentWidthStyleDynamicGap: CGFloat = 30 {
		didSet {
			if segmentWidthStyle == .Dynamic {
				setNeedsDisplay()
			}
		}
	}
	/**
	 Specifies the padding width of header and footer spacing when segmentWidthStyle == .Dynamic.

	 Default is 20
	 */
	public var segmentWidthStyleDynamicHeaderFooterPading: CGFloat = 20 {
		didSet {
			if segmentWidthStyle == .Dynamic {
				setNeedsDisplay()
			}
		}
	}

	/**
	 Specifies the location of the selection indicator.

	 Default is `HMSegmentedControlSelectionIndicatorLocationUp`
	 */
	public var selectionIndicatorLocation: HMSegmentedControlSelectionIndicatorLocation = .Up {
		didSet {
			if selectionIndicatorLocation == .None {
				selectionIndicatorHeight = 0
			}
		}
	}

	/*
	 Specifies the border type.

	 Default is `HMSegmentedControlBorderTypeNone`
	 */
	public var borderType: [HMSegmentedControlBorderType] = [.None] {
		didSet {
			setNeedsDisplay()
		}
	}

	/**
	 Specifies the border color.

	 Default is `[UIColor blackColor]`
	 */
	public lazy var borderColor = UIColor.blackColor()

	/**
	 Specifies the border width.

	 Default is `1.0f`
	 */
	public lazy var borderWidth: CGFloat = 1

	/**
	 Default is YES. Set to NO to deny scrolling by dragging the scrollView by the user.
	 */
	public lazy var userDraggable = true

	/**
	 Default is YES. Set to NO to deny any touch events by the user.
	 */
	public lazy var touchEnabled = true

	/**
	 Default is NO. Set to YES to show a vertical divider between the segments.
	 */
	public lazy var verticalDividerEnabled = false

	/**
	 Index of the currently selected segment.
	 */
	public lazy var selectedSegmentIndex: Int = 0

	/**
	 Height of the selection indicator. Only effective when `HMSegmentedControlSelectionStyle` is either `HMSegmentedControlSelectionStyleTextWidthStripe` or `HMSegmentedControlSelectionStyleFullWidthStripe`.

	 Default is 5.0
	 */
	public lazy var selectionIndicatorHeight: CGFloat = 5

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
	public lazy var selectionIndicatorEdgeInsets = UIEdgeInsetsZero

	/**
	 Inset left and right edges of segments.

	 Default is UIEdgeInsetsMake(0, 5, 0, 5)
	 */
	public lazy var segmentEdgeInset = UIEdgeInsetsMake(0, 5, 0, 5)

	/**
	 Default is YES. Set to NO to disable animation during user selection.
	 */
	public lazy var shouldAnimateUserSelection = true

	public lazy var BadgeRadiu: CGFloat = 6

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

	// MARK:- Private
	private lazy var selectionIndicatorStripLayer = CALayer()
	private lazy var selectionIndicatorBoxLayer = CALayer()
	private lazy var selectionIndicatorArrowLayer = CALayer()
	private lazy var segmentWidth: CGFloat = 1
	private lazy var segmentWidthsArray: [CGFloat] = []
	private lazy var scrollView: HMScrollView = HMScrollView()
	private lazy var badgeMap: [String: CALayer] = [:]
	private lazy var offsetXForCenterAllControl: CGFloat = 0
}

//MARK:- Init
public extension HMSegmentedControl_CodeEagle {

	convenience init(sectionTitles titles: [HMSegmentTitleConvertible]) {
		self.init(frame: CGRectZero)
		sectionTitles = titles
	}

	convenience init(sectionImages off: [UIImage], sectionSelectedImages on: [UIImage]) {
		self.init(frame: CGRectZero)
		sectionImages = off
		sectionSelectedImages = on
		type = .Images
	}

	convenience init(sectionTitles titles: [HMSegmentTitleConvertible], sectionImages off: [UIImage], sectionSelectedImages on: [UIImage]) {
		assert(off.count == titles.count, ":\(__FUNCTION__): Images bounds (\(off.count)) Dont match Title bounds (\(titles.count))")
		self.init(frame: CGRectZero)
		sectionTitles = titles
		sectionImages = off
		sectionSelectedImages = on
		type = .TextImages
	}

	public override func awakeFromNib() {
		super.awakeFromNib()
		segmentWidth = 0
		commonInit()
	}

	private func commonInit() {
		scrollView.scrollsToTop = false
		scrollView.showsHorizontalScrollIndicator = false
		scrollView.showsVerticalScrollIndicator = false
		scrollView.alwaysBounceHorizontal = true
		addSubview(scrollView)

		backgroundColor = UIColor.whiteColor()
		opaque = false

		selectionIndicatorBoxLayer.opacity = selectionIndicatorBoxOpacity
		selectionIndicatorBoxLayer.borderWidth = 1
		contentMode = .Redraw
		addObserver(self, forKeyPath: "frame", options: .New, context: nil)
	}
}

extension HMSegmentedControl_CodeEagle {

	public override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String: AnyObject]?, context: UnsafeMutablePointer<Void>) {
		if keyPath == "frame" {
			updateSegmentsRects()
		}
	}

	public override func layoutSubviews() {
		super.layoutSubviews()
		updateSegmentsRects()
	}
}
//MARK:- Drawing
private extension HMSegmentedControl_CodeEagle {

	func measureTitleAtIndex(index: Int) -> CGSize {
		var size = CGSizeZero

		guard let titles = sectionTitles else { return size }
		if index < 0 || index >= titles.count { return size }
		let data = titles[index].title
		let selected = index == selectedSegmentIndex

		var attributeTitle = data.attributedString
		if attributeTitle == nil {
			guard let titleString = data.string else { return size }
			if let formator = titleFormatter {
				attributeTitle = formator(segmentedControl: self, title: titleString, index: index, selected: selected)
			} else {
				let attribute = selected ? resultingSelectedTitleTextAttributes : resultingTitleTextAttributes
				attributeTitle = NSAttributedString(string: titleString, attributes: attribute)
			}
		}
		size = attributeTitle?.size() ?? CGSizeZero
		return CGRectIntegral(CGRect(origin: CGPointZero, size: size)).size
	}

	func attributedTitleAtIndex(index: Int) -> NSAttributedString? {
		guard let titles = sectionTitles else { return nil }
		if index >= titles.count || index < 0 { return nil }
		let title = titles[index].title
		let selected = index == selectedSegmentIndex

		if let attributedString = title.attributedString { return attributedString }
		guard let titleString = title.string else { return nil }
		var attributeTitle = title.attributedString
		if let formator = titleFormatter {
			attributeTitle = formator(segmentedControl: self, title: titleString, index: index, selected: selected)
		} else {
			var titleAttrs: [String: AnyObject] = selected ? resultingSelectedTitleTextAttributes : resultingTitleTextAttributes
			if let titleColor = titleAttrs[NSForegroundColorAttributeName] as? UIColor {
				titleAttrs[NSForegroundColorAttributeName] = titleColor.CGColor
			}
			attributeTitle = NSAttributedString(string: titleString, attributes: titleAttrs)
		}
		return attributeTitle
	}

	func addBackgroundAndBorderLayerWithRect(fullRect: CGRect) {
		// Background layer
		let backgroundLayer = CALayer()
		backgroundLayer.frame = fullRect
		scrollView.layer.insertSublayer(backgroundLayer, atIndex: 0)

		// Border layer
		let width = fullRect.size.width
		let height = fullRect.size.height
		let total = [
			HMSegmentedControlBorderType.Top: CGRectMake(0, 0, width, borderWidth),
			HMSegmentedControlBorderType.Left: CGRectMake(0, 0, borderWidth, height),
			HMSegmentedControlBorderType.Bottom: CGRectMake(0, height - borderWidth, width, borderWidth),
			HMSegmentedControlBorderType.Right: CGRectMake(width - borderWidth, 0, borderWidth, height)
		]
		for (type, frame) in total {
			if !borderType.contains(type) { continue }
			let borderLayer = CALayer()
			borderLayer.frame = frame
			borderLayer.backgroundColor = borderColor.CGColor
			backgroundLayer.addSublayer(borderLayer)
		}
	}

	func setArrowFrame() {
		selectionIndicatorArrowLayer.frame = frameForSelectionIndicator()

		selectionIndicatorArrowLayer.mask = nil

		let arrowPath = UIBezierPath()

		var p1 = CGPointZero
		var p2 = CGPointZero
		var p3 = CGPointZero

		if selectionIndicatorLocation == .Down {
			p1 = CGPointMake(selectionIndicatorArrowLayer.bounds.size.width / 2, 0)
			p2 = CGPointMake(0, selectionIndicatorArrowLayer.bounds.size.height)
			p3 = CGPointMake(selectionIndicatorArrowLayer.bounds.size.width, selectionIndicatorArrowLayer.bounds.size.height)
		}

		if selectionIndicatorLocation == .Up {
			p1 = CGPointMake(selectionIndicatorArrowLayer.bounds.size.width / 2, selectionIndicatorArrowLayer.bounds.size.height)
			p2 = CGPointMake(selectionIndicatorArrowLayer.bounds.size.width, 0)
			p3 = CGPointMake(0, 0)
		}
		arrowPath.moveToPoint(p1)
		arrowPath.addLineToPoint(p2)
		arrowPath.addLineToPoint(p3)
		arrowPath.closePath()

		let maskLayer = CAShapeLayer()
		maskLayer.frame = selectionIndicatorArrowLayer.bounds
		maskLayer.path = arrowPath.CGPath
		selectionIndicatorArrowLayer.mask = maskLayer
	}

	func frameForSelectionIndicator() -> CGRect {
		var indicatorYOffset: CGFloat = 0

		if selectionIndicatorLocation == .Down {
			indicatorYOffset = bounds.size.height - selectionIndicatorHeight + selectionIndicatorEdgeInsets.bottom
		}

		if selectionIndicatorLocation == .Up {
			indicatorYOffset = selectionIndicatorEdgeInsets.top
		}

		var sectionWidth: CGFloat = 0
		let index = selectedSegmentIndex
		if type == .Text {
			sectionWidth = measureTitleAtIndex(index).width
		} else if type == .Images {
			let idx = Int(index)
			if idx < sectionImages?.count {
				let sectionImage = sectionImages?[idx]
				sectionWidth = sectionImage?.size.width ?? 0
			}
		} else if type == .TextImages {
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
		if selectionStyle == .Arrow {
			let widthToStartOfSelectedIndex = (segmentWidth * floatIndex)
			let widthToEndOfSelectedSegment = widthToStartOfSelectedIndex + segmentWidth
			let x = widthToStartOfSelectedIndex + ((widthToEndOfSelectedSegment - widthToStartOfSelectedIndex) / 2) - (selectionIndicatorHeight / 2)
			return CGRectMake(x - (selectionIndicatorHeight / 2), indicatorYOffset, selectionIndicatorHeight * 2, selectionIndicatorHeight)
		} else {
			if selectionStyle == .TextWidthStripe &&
			sectionWidth <= segmentWidth &&
			segmentWidthStyle != .Dynamic {

				let widthToStartOfSelectedIndex = (segmentWidth * floatIndex)
				let widthToEndOfSelectedSegment = widthToStartOfSelectedIndex + segmentWidth
				let x = ((widthToEndOfSelectedSegment - widthToStartOfSelectedIndex) / 2) + (widthToStartOfSelectedIndex - sectionWidth / 2) + offsetXForCenterAllControl
				return CGRectMake(x + selectionIndicatorEdgeInsets.left, indicatorYOffset, sectionWidth - selectionIndicatorEdgeInsets.right, selectionIndicatorHeight);
			} else {
				if segmentWidthStyle == .Dynamic {

					let x = selectedSegmentOffset + selectionIndicatorEdgeInsets.left + offsetXForCenterAllControl
					let y = indicatorYOffset
					let idx = Int(index)
					let width = segmentWidthsArray[idx] - selectionIndicatorEdgeInsets.right
					let height = selectionIndicatorHeight + selectionIndicatorEdgeInsets.bottom
					return CGRectMake(x, y, width, height)
				}
				return CGRectMake(
					(segmentWidth + selectionIndicatorEdgeInsets.left) * floatIndex + offsetXForCenterAllControl,
					indicatorYOffset,
					segmentWidth - selectionIndicatorEdgeInsets.right,
					selectionIndicatorHeight)
			}
		}
	}

	func frameForFillerSelectionIndicator() -> CGRect {
		if segmentWidthStyle == .Dynamic {
			let idx = Int(UInt(selectedSegmentIndex))
			var width: CGFloat = 0
			if idx < segmentWidthsArray.count {
				width = segmentWidthsArray[idx]
			}
			return CGRectMake(selectedSegmentOffset, 0, width, CGRectGetHeight(frame))
		}
		return CGRectMake(segmentWidth * CGFloat(selectedSegmentIndex), 0, segmentWidth, CGRectGetHeight(self.frame))
	}

	func updateSegmentsRects() {

		scrollView.contentInset = UIEdgeInsetsZero
		scrollView.frame = CGRectMake(0, 0, CGRectGetWidth(frame), CGRectGetHeight(frame))

		if sectionCount > 0 {
			segmentWidth = frame.size.width / CGFloat(sectionCount)
		}

		if let titles = sectionTitles where type == .Text {
			var mutableSegmentWidths: [CGFloat] = []
			for index in 0 ..< titles.count {
				let stringWidth = measureTitleAtIndex(index).width + segmentEdgeInset.left + segmentEdgeInset.right
				if segmentWidthStyle == .Fixed {
					segmentWidth = max(stringWidth, segmentWidth)
				} else if segmentWidthStyle == .Dynamic {
					mutableSegmentWidths.append(stringWidth)
				}
			}
			if mutableSegmentWidths.count > 0 {
				segmentWidthsArray = mutableSegmentWidths
			}
		} else if let images = sectionImages where type == .Images {
			for item in images {
				let imageWidth = item.size.width + segmentEdgeInset.left + segmentEdgeInset.right
				segmentWidth = max(imageWidth, segmentWidth)
			}
		} else if let titles = sectionTitles, images = sectionImages where type == .TextImages {
			var mutableSegmentWidths: [CGFloat] = []
			for index in 0 ..< titles.count {
				let stringWidth = measureTitleAtIndex(index).width + segmentEdgeInset.left + segmentEdgeInset.right
				let imageWidth = images[index].size.width + segmentEdgeInset.left + segmentEdgeInset.right

				if segmentWidthStyle == .Fixed {
					segmentWidth = max(stringWidth, segmentWidth)
				} else if segmentWidthStyle == .Dynamic {
					let width = max(imageWidth, stringWidth)
					mutableSegmentWidths.append(width)
				}
			}
			if mutableSegmentWidths.count > 0 {
				segmentWidthsArray = mutableSegmentWidths
			}
		}
		scrollView.scrollEnabled = userDraggable
		scrollView.contentSize = CGSizeMake(totalSegmentedControlWidth, frame.size.height)
	}

	var sectionCount: UInt {
		var count: UInt = 0
		if type == .Text {
			let acount = sectionTitles?.count ?? 0
			count = UInt(acount)
		} else if type == .Images || type == .TextImages {
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
			if segmentWidthStyle == .Dynamic {
				offset += segmentWidthStyleDynamicGap
			}
			i += 1
		}
		return offset
	}
}
//MARK:- DrawRect
extension HMSegmentedControl_CodeEagle {

	public override func drawRect(rect: CGRect) {
		backgroundColor?.set()
		UIRectFill(bounds)
		updateOffsetXForCEnterAllControl()

		selectionIndicatorArrowLayer.backgroundColor = selectionIndicatorColor.CGColor
		selectionIndicatorStripLayer.backgroundColor = selectionIndicatorColor.CGColor
		selectionIndicatorBoxLayer.backgroundColor = selectionIndicatorColor.CGColor
		selectionIndicatorBoxLayer.borderColor = selectionIndicatorColor.CGColor

		scrollView.layer.backgroundColor = backgroundColor?.CGColor
		scrollView.layer.sublayers = nil

		let oldRect = rect
		switch type {
		case .Text: drawText(oldRect)
		case .Images: drawImage()
		case .TextImages: drawTextImage()
		}
		addBadge()
		addSelectionIndicators()
	}

	private func updateOffsetXForCEnterAllControl() {
		let totalWidth = totalSegmentedControlWidth
		var offsetX: CGFloat = 0

		if totalWidth < bounds.width {
			offsetX = (bounds.width - totalWidth) / 2
		}

		if segmentWidthStyle == .Dynamic {
			offsetX += segmentWidthStyleDynamicHeaderFooterPading
		}

		offsetXForCenterAllControl = offsetX
	}

	private func drawText(oldRect: CGRect) {
		guard let titles = sectionTitles else { return }

		for idx in 0 ..< titles.count {
			let fIndex = CGFloat(idx)
			let size = measureTitleAtIndex(idx)
			let stringWidth = size.width
			let stringHeight = size.height
			var rectDiv = CGRectZero
			var fullRect = CGRectZero

			let locationUp: CGFloat = selectionIndicatorLocation == .Up ? 1 : 0
			let selectionStyleNotBox: CGFloat = selectionStyle != .Box ? 1 : 0
			let toRound = (CGRectGetHeight(frame) - selectionStyleNotBox * selectionIndicatorHeight) / 2 - stringHeight / 2 + selectionIndicatorHeight * locationUp
			var y = round(toRound)

			var rect = CGRectZero
			if segmentWidthStyle == .Fixed {
				var x = segmentWidth * fIndex + (segmentWidth - stringWidth) / 2 + offsetXForCenterAllControl
				rect = CGRectMake(x, y, stringWidth, stringHeight)
				x = segmentWidth * fIndex - verticalDividerWidth / 2
				y = selectionIndicatorHeight * 2
				let height = frame.size.height - selectionIndicatorHeight * 4
				rectDiv = CGRectMake(x, y, verticalDividerWidth, height)
				fullRect = CGRectMake(segmentWidth * fIndex, 0, segmentWidth, oldRect.size.height)
			} else if segmentWidthStyle == .Dynamic {
				var xOffset: CGFloat = offsetXForCenterAllControl

				for (i, width) in segmentWidthsArray.enumerate() {
					if (idx == i) { break }
					xOffset = xOffset + width + segmentWidthStyleDynamicGap
				}
				let widthForIndex: CGFloat = (segmentWidthsArray[safe: idx] ?? 0)
				rect = CGRectMake(xOffset, y, widthForIndex, stringHeight)
				fullRect = CGRectMake(xOffset, 0, widthForIndex, oldRect.size.height)
				rectDiv = CGRectMake(
					xOffset - verticalDividerWidth / 2,
					selectionIndicatorHeight * 2,
					verticalDividerWidth,
					frame.size.height - selectionIndicatorHeight * 4)
			}

			// Fix rect position/size to avoid blurry labels
			rect = CGRectMake(ceil(rect.origin.x), ceil(rect.origin.y), ceil(rect.size.width), ceil(rect.size.height))
			let text = attributedTitleAtIndex(idx)
			let titleLayer = CATextLayer()
			titleLayer.frame = rect
			titleLayer.alignmentMode = kCAAlignmentCenter
			titleLayer.truncationMode = kCATruncationEnd
			titleLayer.string = text
			titleLayer.contentsScale = UIScreen.mainScreen().scale
			scrollView.layer.addSublayer(titleLayer)

			// Badge
			if let title = text?.string {
				let dot = badgeDotForTitle(title)
				let offsetX: CGFloat = segmentWidthStyle == .Dynamic ? BadgeRadiu : 0
				let offsetY: CGFloat = segmentWidthStyle == .Dynamic ? BadgeRadiu / 2: 0
				let centerPoint = CGPointMake(CGRectGetMaxX(titleLayer.frame) - offsetX, CGRectGetMinY(titleLayer.frame) - offsetY)
				dot?.frame = CGRectMake(centerPoint.x, centerPoint.y, BadgeRadiu, BadgeRadiu);
			}

			// Vertical Divider
			addVerticalDivider(rectDiv, idx: idx)
			addBackgroundAndBorderLayerWithRect(fullRect)
		}
	}

	private func drawImage() {
		guard let value = sectionImages else { return }
		for (idx, iconImage) in value.enumerate() {
			let fIdx = CGFloat(idx)
			let icon = iconImage
			let imageWidth = icon.size.width
			let imageHeight = icon.size.height
			let y = round(CGRectGetHeight(frame) - selectionIndicatorHeight) / 2 - imageHeight / 2 + ((selectionIndicatorLocation == .Up) ? selectionIndicatorHeight : 0)
			let x = segmentWidth * fIdx + (segmentWidth - imageWidth) / 2.0
			let rect = CGRectMake(x, y, imageWidth, imageHeight)

			let imageLayer = CALayer()
			imageLayer.frame = rect
			imageLayer.contents = icon.CGImage;
			if selectedSegmentIndex == idx {
				imageLayer.contents = sectionSelectedImages?[safe: idx]?.CGImage ?? icon.CGImage
			}
			scrollView.layer.addSublayer(imageLayer)
			// Vertical Divider
			let rectDiv = CGRectMake((segmentWidth * fIdx) - (verticalDividerWidth / 2), selectionIndicatorHeight * 2, verticalDividerWidth, self.frame.size.height - (selectionIndicatorHeight * 4))
			addVerticalDivider(rectDiv, idx: idx)
			addBackgroundAndBorderLayerWithRect(rect)
		}
	}

	private func drawTextImage() {
		guard let value = sectionImages else { return }

		for (idx, iconImage) in value.enumerate() {
			let fIdx = CGFloat(idx)
			let icon = iconImage
			let imageWidth = icon.size.width
			let imageHeight = icon.size.height
			let stringHeight = measureTitleAtIndex(idx).height
			let yOffset = round(((CGRectGetHeight(frame) - selectionIndicatorHeight) / 2) - (stringHeight / 2))
			var imageXOffset = segmentEdgeInset.left // Start with edge inset
			var textXOffset = segmentEdgeInset.left
			var textWidth: CGFloat = 0

			if segmentWidthStyle == .Fixed {
				imageXOffset = segmentWidth * fIdx + segmentWidth / 2 - imageWidth / 2
				textXOffset = segmentWidth * fIdx
				textWidth = segmentWidth
			} else if segmentWidthStyle == .Dynamic {
				// When we are drawing dynamic widths, we need to loop the widths array to calculate the xOffset
				var xOffset: CGFloat = 0
				for (i, width) in segmentWidthsArray.enumerate() {
					if idx == i { break }
					xOffset += width
				}
				let width = segmentWidthsArray[safe: idx] ?? 0
				imageXOffset = xOffset + width / 2 - (imageWidth / 2)
				textXOffset = xOffset
				textWidth = width
			}

			let imageYOffset = round((CGRectGetHeight(frame) - selectionIndicatorHeight) / 2)
			let imageRect = CGRectMake(imageXOffset, imageYOffset, imageWidth, imageHeight)

			let imageLayer = CALayer()
			imageLayer.frame = imageRect
			imageLayer.contents = icon.CGImage
			if selectedSegmentIndex == idx {
				imageLayer.contents = sectionSelectedImages?[safe: idx]?.CGImage ?? icon.CGImage
			}
			scrollView.layer.addSublayer(imageLayer)

			// Fix rect position/size to avoid blurry labels
			let textRect = CGRectMake(ceil(textXOffset), ceil(yOffset), ceil(textWidth), ceil(stringHeight))
			let text = attributedTitleAtIndex(idx)
			let titleLayer = CATextLayer()
			titleLayer.frame = textRect
			titleLayer.alignmentMode = kCAAlignmentCenter
			titleLayer.string = text
			titleLayer.truncationMode = kCATruncationEnd
			titleLayer.contentsScale = UIScreen.mainScreen().scale
			scrollView.layer.addSublayer(titleLayer)

			// Badge
			if let title = text?.string {
				let dot = badgeDotForTitle(title)
				let centerPoint = CGPointMake(CGRectGetMaxX(titleLayer.frame), CGRectGetMinY(titleLayer.frame))
				dot?.frame = CGRectMake(centerPoint.x, centerPoint.y, BadgeRadiu, BadgeRadiu);
			}
			addBackgroundAndBorderLayerWithRect(imageRect)
		}
	}

	private func addVerticalDivider(rect: CGRect, idx: Int) {
		if verticalDividerEnabled && idx > 0 {
			let verticalDividerLayer = CALayer()
			verticalDividerLayer.frame = rect
			verticalDividerLayer.backgroundColor = self.verticalDividerColor.CGColor
			scrollView.layer.addSublayer(verticalDividerLayer)
		}
	}

	private func addBadge() {
		for key in badgeMap.keys {
			if let layer = self.badgeMap[key] {
				scrollView.layer.addSublayer(layer)
			}
		}
	}

	private func addSelectionIndicators() {
		if selectedSegmentIndex == HMSegmentedControlIndex.NoSegment.rawValue { return }
		if selectionStyle == .Arrow {
			if selectionIndicatorArrowLayer.superlayer == nil {
				setArrowFrame()
				scrollView.layer.addSublayer(selectionIndicatorArrowLayer)
			}
		} else {
			if selectionIndicatorStripLayer.superlayer == nil {
				selectionIndicatorStripLayer.frame = frameForSelectionIndicator()
				scrollView.layer.addSublayer(selectionIndicatorStripLayer)

				if selectionStyle == .Box && selectionIndicatorBoxLayer.superlayer == nil {
					self.selectionIndicatorBoxLayer.frame = frameForFillerSelectionIndicator()
					scrollView.layer.insertSublayer(selectionIndicatorBoxLayer, atIndex: 0)
				}
			}
		}
	}

	public override func willMoveToSuperview(newSuperview: UIView?) {
		if newSuperview == nil { return }
		if sectionTitles != nil || sectionImages != nil {
			updateSegmentsRects()
		}
	}
}
//MARK:- Touch
extension HMSegmentedControl_CodeEagle {

	public override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
		guard let location = touches.first?.locationInView(self) else { return }
		if !CGRectContainsPoint(bounds, location) { return }
		var segment = 0
		if segmentWidthStyle == .Fixed {
			segment = Int((location.x + scrollView.contentOffset.x - offsetXForCenterAllControl) / segmentWidth)
		} else if segmentWidthStyle == .Dynamic {
			var widthLeft = location.x + scrollView.contentOffset.x - offsetXForCenterAllControl
			for width in segmentWidthsArray {
				widthLeft -= width + segmentWidthStyleDynamicGap
				if widthLeft <= 0 { break }
				segment += 1
			}
		}

		var sectionsCount = 0

		if type == .Images {
			sectionsCount = sectionImages?.count ?? 0
		} else if type == .TextImages || type == .Text {
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

	func setSelectedSegmentIndex(index: Int, animated: Bool = false, notify: Bool = false) {
		selectedSegmentIndex = index
		setNeedsDisplay()

		if selectedSegmentIndex == HMSegmentedControlIndex.NoSegment.rawValue {
			[selectionIndicatorArrowLayer, selectionIndicatorStripLayer, selectionIndicatorBoxLayer].forEach({ (layer) -> () in
				layer.removeFromSuperlayer()
			})
		} else {
			scrollToSelectedSegmentIndex(animated)

			if animated {
				// If the selected segment layer is not added to the super layer, that means no
				// index is currently selected, so add the layer then move it to the new
				// segment index without animating.
				if selectionStyle == .Arrow {
					if selectionIndicatorArrowLayer.superlayer == nil {
						scrollView.layer.addSublayer(selectionIndicatorArrowLayer)
						setSelectedSegmentIndex(index, notify: true)
						return
					}
				} else {
					if selectionIndicatorStripLayer.superlayer == nil {
						scrollView.layer.addSublayer(selectionIndicatorStripLayer)

						if selectionStyle == .Box && selectionIndicatorBoxLayer.superlayer == nil {
							scrollView.layer.insertSublayer(selectionIndicatorBoxLayer, atIndex: 0)
						}
						setSelectedSegmentIndex(index, notify: true)
						return
					}
				}

				if notify {
					notifyForSegmentChangeToIndex(UInt(index))
				}

				// Restore CALayer animations
				selectionIndicatorArrowLayer.actions = nil
				selectionIndicatorStripLayer.actions = nil
				selectionIndicatorBoxLayer.actions = nil

				// Animate to new position
				CATransaction.begin()
				CATransaction.setAnimationDuration(0.15)
				CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(controlPoints: 0.4, 0.1, 0.3, 1.2))
				setArrowFrame()
				selectionIndicatorBoxLayer.frame = frameForSelectionIndicator()
				selectionIndicatorStripLayer.frame = frameForSelectionIndicator()
				selectionIndicatorBoxLayer.frame = frameForFillerSelectionIndicator()
				CATransaction.commit()
			}
		}
	}

	func notifyForSegmentChangeToIndex(index: UInt) {
		if superview != nil {
			sendActionsForControlEvents(UIControlEvents.ValueChanged)
		}
		indexChangeBlock?(index)
	}
}
//MARK:- Scrolling
private extension HMSegmentedControl_CodeEagle {

	var totalSegmentedControlWidth: CGFloat {
		if segmentWidthStyle == .Fixed {
			return segmentWidth * CGFloat(sectionCount)
		} else {
			return segmentWidthsArray.reduce(0, combine: +) + CGFloat(sectionCount - 1) * segmentWidthStyleDynamicGap + segmentWidthStyleDynamicHeaderFooterPading * 2
		}
	}

	func scrollToSelectedSegmentIndex(animated: Bool) {
		var rectForSelectedIndex = CGRectZero
		var _selectedSegmentOffset: CGFloat = 0
		if segmentWidthStyle == .Fixed {
			rectForSelectedIndex = CGRectMake(
				segmentWidth * CGFloat(selectedSegmentIndex),
				0,
				segmentWidth,
				frame.size.height)

			_selectedSegmentOffset = (CGRectGetWidth(frame) / 2) - (segmentWidth / 2)
		} else if segmentWidthStyle == .Dynamic {
			let offsetter = selectedSegmentOffset
			var width: CGFloat = 0
			if selectedSegmentIndex < segmentWidthsArray.count {
				width = segmentWidthsArray[selectedSegmentIndex]
			}
			rectForSelectedIndex = CGRectMake(offsetter, 0, width, frame.size.height)
			_selectedSegmentOffset = (CGRectGetWidth(self.frame) / 2) - (width / 2)
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
			NSFontAttributeName: UIFont.systemFontOfSize(19),
			NSForegroundColorAttributeName: UIColor.blackColor()
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

	public func toggleMatchTitle(title: HMSegmentTitleConvertible?, hide: Bool) {
		guard let key = title?.title.string ?? title?.title.attributedString?.string else { return }
		hide ? removeBadgeForTitle(key) : addBadgeForTitle(key)
	}

	private func addBadgeForTitle(title: String) {
		var dot: CALayer! = badgeDotForTitle(title)
		if dot == nil {
			dot = CALayer()
			dot.backgroundColor = UIColor.redColor().CGColor
			dot.frame = CGRectMake(0, 0, BadgeRadiu, BadgeRadiu)
			dot.cornerRadius = BadgeRadiu / 2
			dot.masksToBounds = true
		}
		dot?.hidden = false
		badgeMap[title] = dot
		setNeedsDisplay()
	}

	private func removeBadgeForTitle(title: String) {
		let dot = badgeDotForTitle(title)
		dot?.removeFromSuperlayer()
		badgeMap.removeValueForKey(title)
	}

	private func badgeDotForTitle(title: String) -> CALayer? {
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
	override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
		if dragging {
			super.touchesBegan(touches, withEvent: event)
			return
		}
		nextResponder()?.touchesBegan(touches, withEvent: event)
	}

	override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
		if dragging {
			super.touchesMoved(touches, withEvent: event)
			return
		}
		nextResponder()?.touchesMoved(touches, withEvent: event)
	}

	override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
		if dragging {
			super.touchesEnded(touches, withEvent: event)
			return
		}
		nextResponder()?.touchesEnded(touches, withEvent: event)
	}
}