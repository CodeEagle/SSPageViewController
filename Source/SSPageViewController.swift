//
//  SSPageViewController.swift
//  SSPageViewController
//
//  Created by LawLincoln on 16/3/11.
//  Copyright © 2016年 Luoo. All rights reserved.
//

import UIKit
import HMSegmentedControl_CodeEagle
import SnapKit

//MARK:- SSPageViewController
/// SSPageViewController
public final class SSPageViewController < Template: SSPageViewContentProtocol, Delegate: SSPageViewDelegate where Template == Delegate.Template >: UIViewController, UIScrollViewDelegate {

	public typealias TemplateConfigurationClosure = (display: Template, backup: Template) -> Void

	// MARK:- Public
	public private(set) lazy var indicator: UIPageControl = UIPageControl()
	public private(set) lazy var scrollView = UIScrollView()
	public private(set) lazy var segment: HMSegmentedControl_CodeEagle = HMSegmentedControl_CodeEagle()

	public weak var ss_delegate: Delegate?

	public var initializeTemplateConfiguration: TemplateConfigurationClosure? {
		didSet {
			initializeTemplateConfiguration?(display: _display, backup: _backup)
		}
	}

	public var configurationBlock: TemplateConfigurationClosure? {
		didSet {
			configurationBlock?(display: _display, backup: _backup)
			customConfigurationDone()
		}
	}

	public var indicatorAlignStyle: NSTextAlignment = .Center {
		didSet {
			configureIndicator()
		}
	}

	public var loopInterval: NSTimeInterval = 0 {
		didSet {
			addDisplayNextTask()
		}
	}

	public var showsSegment = false {
		didSet {
			segment.snp_remakeConstraints { (make) -> Void in
				make.top.left.right.equalTo(view)
				make.height.equalTo(showsSegment ? 44 : 0)
			}
		}
	}

	public var showsIndicator: Bool = false {
		didSet {
			indicator.hidden = !showsIndicator
		}
	}

	// MARK:- Private
	private var _display: Template!
	private var _backup: Template!

	private var _direction: UIPageViewControllerNavigationOrientation!
	private var _task: CancelableTask?
	private var _scrollTask: CancelableTask?

	private var _isHorizontal: Bool { return _direction == .Horizontal }
	private var _displayView: UIView! { return _display.ss_content }
	private var _backupView: UIView! { return _backup.ss_content }
	private var _boundsWidth: CGFloat { return view.bounds.width }
	private var _boundsHeight: CGFloat { return view.bounds.height }

	// MARK:- LifeCycle
	deinit {
		_display = nil
		_backup = nil
		scrollView.delegate = nil
	}

	override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
		super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
	}

	public required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}

	public convenience init(scrollDirection: UIPageViewControllerNavigationOrientation = .Horizontal) {
		self.init(nibName: nil, bundle: nil)
		_direction = scrollDirection
		_display = Template()
		_backup = Template()
		automaticallyAdjustsScrollViewInsets = false
		setup()
	}

	private var _ignoreScroll = false
	public func scrollTo(template: (Template) -> Template, direction: UIPageViewControllerNavigationDirection) {
		_backup = template(_backup)
		_ignoreScroll = true

		let hasNextAfterBackup = _backup.ss_nextId != nil

		if direction == .Forward {

			_displayView.snp_remakeConstraints(closure: { (make) -> Void in
				if _isHorizontal {
					make.left.equalTo(scrollView).offset(_displayView.frame.origin.x)
					make.top.bottom.equalTo(scrollView)
				} else {
					make.top.equalTo(scrollView).offset(_displayView.frame.origin.y)
					make.left.right.equalTo(scrollView)
				}
				make.width.height.equalTo(scrollView)
			})

			_backupView.snp_remakeConstraints(closure: { (make) -> Void in
				if _isHorizontal {
					make.left.equalTo(_displayView.snp_right)
					make.right.equalTo(scrollView).offset(hasNextAfterBackup ? -_boundsWidth : 0)
					make.top.bottom.equalTo(scrollView)
				} else {
					make.top.equalTo(_displayView.snp_bottom)
					make.bottom.equalTo(scrollView).offset(hasNextAfterBackup ? -_boundsHeight : 0)
					make.left.right.equalTo(scrollView)
				}
				make.width.height.equalTo(scrollView)
			})

		} else {

			let offset = _isHorizontal ? (_displayView.frame.origin.x - _boundsWidth) : (_displayView.frame.origin.y - _boundsHeight)
			_backupView.snp_remakeConstraints(closure: { (make) -> Void in
				if _isHorizontal {
					make.left.equalTo(scrollView).offset(offset)
					make.top.bottom.equalTo(scrollView)
				} else {
					make.top.equalTo(scrollView).offset(offset)
					make.left.right.equalTo(scrollView)
				}
				make.width.height.equalTo(scrollView)
			})

			_displayView.snp_remakeConstraints(closure: { (make) -> Void in
				if _isHorizontal {
					make.left.equalTo(_backupView.snp_right)
					make.right.equalTo(scrollView)
					make.top.bottom.equalTo(scrollView)
				} else {
					make.top.equalTo(_backupView.snp_bottom)
					make.bottom.equalTo(scrollView)
					make.left.right.equalTo(scrollView)
				}
				make.width.height.equalTo(scrollView)
			})

		}
		var point = scrollView.contentOffset

		if direction == .Forward {
			if _isHorizontal {
				point.x += _boundsWidth
			} else {
				point.y += _boundsHeight
			}
		} else {
			if _isHorizontal {
				point.x -= _boundsWidth
			} else {
				point.y -= _boundsHeight
			}
		}

		scrollView.setNeedsLayout()
		scrollView.setContentOffset(point, animated: true)
	}

	// MARK:- UIScrollViewDelegate
	public func scrollViewDidScroll(scrollView: UIScrollView) {
		dealScroll(scrollView)
	}

	public func scrollViewDidEndScrollingAnimation(scrollView: UIScrollView) {
		dealEnd(scrollView)
	}

	public func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
		dealEnd(scrollView)
	}

	private func dealScroll(scrollView: UIScrollView) {
		CancelableTaskManager.cancel(_task)
		CancelableTaskManager.cancel(_scrollTask)
		if _ignoreScroll { return }

		let offset = scrollView.contentOffset
		let standarValue = _isHorizontal ? offset.x : offset.y
		let backupPoint = _isHorizontal ? _backupView.frame.origin.x : _backupView.frame.origin.y
		let displayPoint = _isHorizontal ? _displayView.frame.origin.x : _displayView.frame.origin.y
		let displayLen = _isHorizontal ? _displayView.frame.size.width : _displayView.frame.size.height
		if displayPoint - standarValue > 0 {
			let targetBackupPoint = displayPoint - displayLen
			if let preId = _display.ss_previousId {
				if _backup.ss_identifer != preId {
					ss_delegate?.pageView(self, configureForView: _backup, beforeView: _display)
				}
				if backupPoint != targetBackupPoint {
					_backupView.snp_remakeConstraints(closure: { (make) -> Void in
						if _isHorizontal {
							make.left.equalTo(scrollView)
							make.top.bottom.equalTo(scrollView)
						} else {
							make.top.equalTo(scrollView)
							make.left.right.equalTo(scrollView)
						}
						make.width.height.equalTo(scrollView)
					})
					_displayView.snp_remakeConstraints(closure: { (make) -> Void in
						if _isHorizontal {
							make.right.equalTo(scrollView).offset(-_boundsWidth)
							make.left.equalTo(_backupView.snp_right)
							make.top.bottom.equalTo(scrollView)
						} else {
							make.top.equalTo(_backupView.snp_bottom)
							make.left.right.equalTo(scrollView)
							make.bottom.equalTo(scrollView).offset(-_boundsHeight)
						}
						make.width.height.equalTo(scrollView)
					})
				}
			}
		} else {
			let targetBackupPoint = displayPoint + displayLen
			if let nextId = _display.ss_nextId {
				if _backup.ss_identifer != nextId {
					ss_delegate?.pageView(self, configureForView: _backup, afterView: _display)
				}

				if backupPoint != targetBackupPoint {

					_displayView.snp_remakeConstraints(closure: { (make) -> Void in
						if _isHorizontal {
							make.left.equalTo(scrollView).offset(_boundsWidth)
							make.top.bottom.equalTo(scrollView)
						} else {
							make.top.equalTo(scrollView).offset(_boundsHeight)
							make.left.right.equalTo(scrollView)
						}
						make.width.height.equalTo(scrollView)
					})
					_backupView.snp_remakeConstraints(closure: { (make) -> Void in
						if _isHorizontal {
							make.right.equalTo(scrollView).offset(-_boundsWidth)
							make.left.equalTo(_displayView.snp_right)
							make.top.bottom.equalTo(scrollView)
						} else {
							make.top.equalTo(_displayView.snp_bottom)
							make.left.right.equalTo(scrollView)
							make.bottom.equalTo(scrollView).offset(-_boundsHeight)
						}
						make.width.height.equalTo(scrollView)
					})
				}
			}
		}
		scrollView.setNeedsLayout()
	}

	private func dealEnd(scrollView: UIScrollView) {
		_ignoreScroll = false
		let lastPoint = scrollView.contentOffset

		let displayPoint = _isHorizontal ? _displayView.frame.origin.x : _displayView.frame.origin.y
		let backupPoint = _isHorizontal ? _backupView.frame.origin.x : _backupView.frame.origin.y
		let standar = _isHorizontal ? lastPoint.x : lastPoint.y
		let b = abs(backupPoint - standar)
		let s = abs(displayPoint - standar)
		if b < s { swap(&_display, &_backup) }
		let reachHeader = _isHorizontal ? (lastPoint.x == 0) : (lastPoint.y == 0)
		let reachFooter = _isHorizontal ? (lastPoint.x == scrollView.bounds.size.width * 2) : (lastPoint.y == scrollView.bounds.size.height * 2)
		var target: CGFloat = 0
		if reachHeader {
			if _display?.ss_previousId != nil {
				target = _isHorizontal ? _boundsWidth : _boundsHeight
			}
			let point = CGPointMake(_isHorizontal ? target : 0, _isHorizontal ? 0 : target)
			scrollView.setContentOffset(point, animated: false)
		} else if reachFooter {
			target = _isHorizontal ? _boundsWidth * 2: _boundsHeight * 2
			if _display?.ss_nextId != nil {
				target = _isHorizontal ? _boundsWidth : _boundsHeight
			}
			let point = CGPointMake(_isHorizontal ? target : 0, _isHorizontal ? 0 : target)
			scrollView.setContentOffset(point, animated: false)
		} else {
			target = _isHorizontal ? _boundsWidth : _boundsHeight
			let point = CGPointMake(_isHorizontal ? target : 0, _isHorizontal ? 0 : target)
			scrollView.setContentOffset(point, animated: false)
		}

		_displayView.snp_remakeConstraints(closure: { (make) -> Void in
			if _isHorizontal {
				if target == _boundsWidth * 2 {
					make.right.equalTo(scrollView)
				} else {
					make.left.equalTo(scrollView).offset(target)
				}
				make.top.bottom.equalTo(scrollView)
			} else {
				if target == _boundsHeight * 2 {
					make.top.equalTo(scrollView).offset(_boundsHeight)
				} else {
					make.top.equalTo(scrollView).offset(target)
				}
				make.left.right.equalTo(scrollView)
			}
			make.width.height.equalTo(scrollView)
		})

		_backupView.snp_remakeConstraints(closure: { (make) -> Void in
			if _isHorizontal {
				if target == _boundsWidth * 2 {
					make.right.equalTo(_displayView.snp_left)
					make.left.equalTo(scrollView).offset(_boundsWidth)
				} else {
					make.left.equalTo(_displayView.snp_right)
					make.right.equalTo(scrollView)
				}
				make.top.bottom.equalTo(scrollView)
			} else {
				make.top.equalTo(_displayView.snp_bottom)
				make.left.right.equalTo(scrollView)
				make.bottom.equalTo(scrollView).offset(-target)
			}
			make.width.height.equalTo(scrollView)
		})

		scrollView.setNeedsLayout()
		ss_delegate?.pageView(self, didScrollToView: _display)

		addDisplayNextTask()
	}
}
//MARK:- Private Function
private extension SSPageViewController {

	func setup() {
		view.backgroundColor = UIColor.whiteColor()
		initializeSegment()
		initializeScrollview()
		initializeIndicator()
	}

	func initializeScrollview() {

		view.addSubview(scrollView)
		scrollView.addSubview(_displayView)
		scrollView.addSubview(_backupView)

		_displayView.snp_makeConstraints { (make) -> Void in
			make.top.left.bottom.height.width.equalTo(scrollView)
		}
		_backupView.snp_makeConstraints { (make) -> Void in
			make.width.height.equalTo(scrollView)
			if _isHorizontal {
				make.top.bottom.equalTo(scrollView)
				make.left.equalTo(_displayView.snp_right)
				make.right.equalTo(scrollView).offset(-_boundsWidth)
			} else {
				make.left.right.equalTo(scrollView)
				make.top.equalTo(_displayView.snp_bottom)
				make.bottom.equalTo(scrollView).offset(-_boundsHeight)
			}
		}

		scrollView.snp_makeConstraints { (make) -> Void in
			make.top.equalTo(segment.snp_bottom)
			make.left.bottom.right.equalTo(view)
		}
		_isHorizontal ? (scrollView.alwaysBounceHorizontal = true) : (scrollView.alwaysBounceVertical = true)

		let factorX: CGFloat = _isHorizontal ? 3 : 1
		let factorY: CGFloat = _isHorizontal ? 1 : 3
		scrollView.contentSize = CGSizeMake(_boundsWidth * factorX, _boundsHeight * factorY)
		scrollView.translatesAutoresizingMaskIntoConstraints = false
		scrollView.showsHorizontalScrollIndicator = false
		scrollView.showsVerticalScrollIndicator = false
		scrollView.scrollsToTop = false
		scrollView.backgroundColor = UIColor.whiteColor()
		scrollView.pagingEnabled = true
		scrollView.delegate = self
	}

	func initializeSegment() {
		view.addSubview(segment)
		segment.snp_makeConstraints { (make) -> Void in
			make.top.left.right.equalTo(view)
			make.height.equalTo(0)
		}
	}

	func initializeIndicator() {
		view.addSubview(indicator)
		indicator.hidden = true
		configureIndicator()
	}

	func configureIndicator() {
		if !_isHorizontal {
			indicator.transform = CGAffineTransformMakeRotation(CGFloat(M_PI * 90 / 180.0))
		}
		indicator.sizeToFit()
		var inset = UIEdgeInsetsZero
		switch indicatorAlignStyle {
		case .Left: _isHorizontal ? (inset.left = 10) : (inset.top = 10)
		case .Right: _isHorizontal ? (inset.right = 10) : (inset.bottom = 10)
		default: break
		}
		if _isHorizontal {
			inset.bottom = 10
		} else {
			inset.right = 10
		}

		indicator.snp_removeConstraints()
		indicator.snp_makeConstraints { (make) -> Void in
			if _isHorizontal {
				make.bottom.equalTo(inset.bottom)
				if inset.left != 0 { make.left.equalTo(inset.left) }
				if inset.right != 0 { make.right.equalTo(inset.right) }
				if indicatorAlignStyle == .Center {
					make.right.left.equalTo(indicator.superview!)
				}
			} else {
				make.right.equalTo(inset.right)
				if inset.top != 0 { make.top.equalTo(inset.top) }
				if inset.bottom != 0 { make.bottom.equalTo(inset.bottom) }
				if indicatorAlignStyle == .Center {
					make.top.bottom.equalTo(indicator.superview!)
				}
			}
		}
		UIView.animateWithDuration(0.2) { () -> Void in
			self.view.setNeedsLayout()
		}
	}

	func customConfigurationDone() {
		let hideAndStall = !(_display.ss_nextId == nil && _display.ss_previousId == nil)
		showsIndicator = hideAndStall
		scrollView.scrollEnabled = hideAndStall

		_displayView.snp_removeConstraints()
		_backupView.snp_removeConstraints()

		let hasPrevious = _display.ss_previousId != nil

		_displayView.snp_remakeConstraints { (make) -> Void in
			if hasPrevious {
				if _isHorizontal {
					make.top.bottom.equalTo(scrollView)
					make.left.equalTo(scrollView).offset(_boundsWidth)
				} else {
					make.top.equalTo(scrollView).offset(_boundsHeight)
					make.left.right.equalTo(scrollView)
				}
				make.width.height.equalTo(scrollView)
			} else {
				make.top.left.bottom.height.width.equalTo(scrollView)
			}
		}

		_backupView.snp_remakeConstraints { (make) -> Void in
			make.width.height.equalTo(scrollView)
			if _isHorizontal {
				make.top.bottom.equalTo(scrollView)
				make.left.equalTo(_displayView.snp_right)
				make.right.equalTo(scrollView).offset(hasPrevious ? 0 : -_boundsWidth)
			} else {
				make.left.right.equalTo(scrollView)
				make.top.equalTo(_displayView.snp_bottom)
				make.bottom.equalTo(scrollView).offset(hasPrevious ? 0 : -_boundsHeight)
			}
		}
		let point = hasPrevious ? CGPointMake(_isHorizontal ? _boundsWidth : 0, _isHorizontal ? 0 : _boundsHeight) : CGPointZero
		scrollView.setContentOffset(point, animated: false)
		view.setNeedsLayout()
	}

	func addDisplayNextTask() {
		CancelableTaskManager.cancel(_task)
		if loopInterval == 0 || (_display.ss_nextId == nil && _display.ss_previousId == nil) { return }
		_task = CancelableTaskManager.delay(loopInterval, work: { [weak self]() -> Void in
			guard let sself = self else { return }
			let x = sself._isHorizontal ? sself.scrollView.contentOffset.x + sself._boundsWidth: 0
			let y = sself._isHorizontal ? 0 : sself.scrollView.contentOffset.y + sself._boundsHeight
			sself.scrollView.setContentOffset(CGPointMake(x, y), animated: true)
		})
	}
}

//MARK:-
//MARK:- SSPageViewContentProtocol
/// SSPageViewContentProtocol
public protocol SSPageViewContentProtocol {
	var ss_identifer: String { get }
	var ss_previousId: String? { get }
	var ss_nextId: String? { get }
	var ss_content: UIView { get }
	init()
}

private func == (lhs: SSPageViewContentProtocol, rhs: SSPageViewContentProtocol) -> Bool {
	return lhs.ss_identifer == rhs.ss_identifer
}
//MARK:-
//MARK:- SSPageViewDelegateProtocol
/// SSPageViewDelegateProtocol
public protocol SSPageViewDelegate: class {
	associatedtype Template: SSPageViewContentProtocol
	func pageView(pageView: SSPageViewController<Template, Self>, configureForView view: Template, afterView: Template)
	func pageView(pageView: SSPageViewController<Template, Self>, configureForView view: Template, beforeView: Template)
	func pageView(pageView: SSPageViewController<Template, Self>, didScrollToView view: Template)
}

//MARK:- Help
private extension NSRange {
	func contain(number: CGFloat) -> Bool {
		let target = Int(number)
		return location <= target && target <= length
	}
}

//MARK:- CancelableTaskManager
typealias CancelableTask = (cancel: Bool) -> Void

struct CancelableTaskManager {

	static func delay(time: NSTimeInterval, work: dispatch_block_t) -> CancelableTask? {

		var finalTask: CancelableTask?

		let cancelableTask: CancelableTask = { cancel in
			if cancel {
				finalTask = nil // key
			} else {
				dispatch_async(dispatch_get_main_queue(), work)
			}
		}

		finalTask = cancelableTask

		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(time * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) {
			if let task = finalTask {
				task(cancel: false)
			}
		}

		return finalTask
	}

	static func cancel(cancelableTask: CancelableTask?) {
		cancelableTask?(cancel: true)
	}
}
