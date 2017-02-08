//
//  SSPageViewController.swift
//  SSPageViewController
//
//  Created by LawLincoln on 16/3/11.
//  Copyright © 2016年 Luoo. All rights reserved.
//

import UIKit
#if !PACKING_FOR_APPSTORE
    import HMSegmentedControl_CodeEagle
    import SnapKit
#endif

//MARK:- SSPageViewController
/// SSPageViewController
public final class SSPageViewController < Template: SSPageViewContentProtocol, Delegate: SSPageViewDelegate>: UIViewController, UIScrollViewDelegate where Template == Delegate.Template  {

	public typealias TemplateConfigurationClosure = (_ display: Template, _ backup: Template) -> Void

	// MARK:- Public
	public fileprivate(set) lazy var indicator: UIPageControl = UIPageControl()
	public fileprivate(set) lazy var scrollView = UIScrollView()
	public fileprivate(set) lazy var segment: HMSegmentedControl_CodeEagle = HMSegmentedControl_CodeEagle()
    public var itemLength: CGFloat {
        let size = view.bounds.size
        return _isHorizontal ? size.width : size.height
    }
    
	public weak var ss_delegate: Delegate?

	public var initializeTemplateConfiguration: TemplateConfigurationClosure? {
		didSet {
			initializeTemplateConfiguration?(_display, _backup)
		}
	}

	public var configurationBlock: TemplateConfigurationClosure? {
		didSet {
			configurationBlock?(_display, _backup)
			customConfigurationDone()
		}
	}

	public var indicatorAlignStyle: NSTextAlignment = .center {
		didSet {
			configureIndicator()
		}
	}

	public var loopInterval: TimeInterval = 0 {
		didSet {
			addDisplayNextTask()
		}
	}

	public var showsSegment = false {
		didSet {
			segment.snp.remakeConstraints { (make) -> Void in
				make.top.left.right.equalTo(view)
				make.height.equalTo(showsSegment ? 44 : 0)
			}
		}
	}

    public var showsIndicator: Bool = false {
        didSet { indicator.isHidden = !showsIndicator }
    }
    
    public var currentOffset: ((CGFloat) -> ())?

	// MARK:- Private
	fileprivate var _display: Template!
	fileprivate var _backup: Template!

	fileprivate var _direction: UIPageViewControllerNavigationOrientation!
	fileprivate var _task: SSCancelableTask?

	fileprivate var _isHorizontal: Bool { return _direction == .horizontal }
	fileprivate var _displayView: UIView! { return _display.ss_content }
	fileprivate var _backupView: UIView! { return _backup.ss_content }
	fileprivate var _boundsWidth: CGFloat { return view.bounds.width }
	fileprivate var _boundsHeight: CGFloat { return view.bounds.height }

	// MARK:- LifeCycle
	deinit {
		_display = nil
		_backup = nil
		scrollView.delegate = nil
	}

	override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
		super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
	}

	public required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}

	public convenience init(scrollDirection: UIPageViewControllerNavigationOrientation = .horizontal) {
		self.init(nibName: nil, bundle: nil)
		_direction = scrollDirection
		_display = Template()
		_backup = Template()
		automaticallyAdjustsScrollViewInsets = false
		setup()
	}

	fileprivate var _ignoreScroll = false
    
	public func scrollTo(_ template: (Template) -> Template, direction: UIPageViewControllerNavigationDirection) {
		_backup = template(_backup)
		_ignoreScroll = true

		let hasNextAfterBackup = _backup.ss_nextId != nil

		if direction == .forward {

			_displayView.snp.remakeConstraints({ (make) -> Void in
				if _isHorizontal {
					make.left.equalTo(scrollView).offset(_displayView.frame.origin.x)
					make.top.bottom.equalTo(scrollView)
				} else {
					make.top.equalTo(scrollView).offset(_displayView.frame.origin.y)
					make.left.right.equalTo(scrollView)
				}
				make.width.height.equalTo(scrollView)
			})

			_backupView.snp.remakeConstraints({ (make) -> Void in
				if _isHorizontal {
					make.left.equalTo(_displayView.snp.right)
					make.right.equalTo(scrollView).offset(hasNextAfterBackup ? -_boundsWidth : 0)
					make.top.bottom.equalTo(scrollView)
				} else {
					make.top.equalTo(_displayView.snp.bottom)
					make.bottom.equalTo(scrollView).offset(hasNextAfterBackup ? -_boundsHeight : 0)
					make.left.right.equalTo(scrollView)
				}
				make.width.height.equalTo(scrollView)
			})

		} else {

			let offset = _isHorizontal ? (_displayView.frame.origin.x - _boundsWidth) : (_displayView.frame.origin.y - _boundsHeight)
			_backupView.snp.remakeConstraints({ (make) -> Void in
				if _isHorizontal {
					make.left.equalTo(scrollView).offset(offset)
					make.top.bottom.equalTo(scrollView)
				} else {
					make.top.equalTo(scrollView).offset(offset)
					make.left.right.equalTo(scrollView)
				}
				make.width.height.equalTo(scrollView)
			})

			_displayView.snp.remakeConstraints({ (make) -> Void in
				if _isHorizontal {
					make.left.equalTo(_backupView.snp.right)
					make.right.equalTo(scrollView)
					make.top.bottom.equalTo(scrollView)
				} else {
					make.top.equalTo(_backupView.snp.bottom)
					make.bottom.equalTo(scrollView)
					make.left.right.equalTo(scrollView)
				}
				make.width.height.equalTo(scrollView)
			})

		}
		var point = scrollView.contentOffset

		if direction == .forward {
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
	public func scrollViewDidScroll(_ scrollView: UIScrollView) {
		dealScroll(scrollView)
	}

	public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
		dealEnd(scrollView)
	}

	public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
		dealEnd(scrollView)
	}

	fileprivate func dealScroll(_ scrollView: UIScrollView) {
		SSCancelableTaskManager.cancel(_task)
        let offset = scrollView.contentOffset
        let standarValue = _isHorizontal ? offset.x : offset.y
        currentOffset?(standarValue)
		if _ignoreScroll { return }
		let backupPoint = _isHorizontal ? _backupView.frame.origin.x : _backupView.frame.origin.y
		let displayPoint = _isHorizontal ? _displayView.frame.origin.x : _displayView.frame.origin.y
		let displayLen = _isHorizontal ? _displayView.frame.size.width : _displayView.frame.size.height
		if displayPoint - standarValue > 0 {
			let targetBackupPoint = displayPoint - displayLen
			if let preId = _display.ss_previousId {
				if _backup.ss_identifer != preId || _backup.ss_identifer == "" {
					ss_delegate?.pageView(self, configureForView: _backup, beforeView: _display)
				}
				if backupPoint != targetBackupPoint {
					_backupView.snp.remakeConstraints({ (make) -> Void in
						if _isHorizontal {
							make.left.equalTo(scrollView)
							make.top.bottom.equalTo(scrollView)
						} else {
							make.top.equalTo(scrollView)
							make.left.right.equalTo(scrollView)
						}
						make.width.height.equalTo(scrollView)
					})
					_displayView.snp.remakeConstraints({ (make) -> Void in
						if _isHorizontal {
							make.right.equalTo(scrollView).offset(-_boundsWidth)
							make.left.equalTo(_backupView.snp.right)
							make.top.bottom.equalTo(scrollView)
						} else {
							make.top.equalTo(_backupView.snp.bottom)
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
				if _backup.ss_identifer != nextId || _backup.ss_identifer == "" {
					ss_delegate?.pageView(self, configureForView: _backup, afterView: _display)
				}

				if backupPoint != targetBackupPoint {

					_displayView.snp.remakeConstraints({ (make) -> Void in
						if _isHorizontal {
							make.left.equalTo(scrollView).offset(_boundsWidth)
							make.top.bottom.equalTo(scrollView)
						} else {
							make.top.equalTo(scrollView).offset(_boundsHeight)
							make.left.right.equalTo(scrollView)
						}
						make.width.height.equalTo(scrollView)
					})
					_backupView.snp.remakeConstraints({ (make) -> Void in
						if _isHorizontal {
							make.right.equalTo(scrollView).offset(-_boundsWidth)
							make.left.equalTo(_displayView.snp.right)
							make.top.bottom.equalTo(scrollView)
						} else {
							make.top.equalTo(_displayView.snp.bottom)
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

	fileprivate func dealEnd(_ scrollView: UIScrollView) {
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
			let point = CGPoint(x: _isHorizontal ? target : 0, y: _isHorizontal ? 0 : target)
			scrollView.setContentOffset(point, animated: false)
		} else if reachFooter {
			target = _isHorizontal ? _boundsWidth * 2: _boundsHeight * 2
			if _display?.ss_nextId != nil {
				target = _isHorizontal ? _boundsWidth : _boundsHeight
			}
			let point = CGPoint(x: _isHorizontal ? target : 0, y: _isHorizontal ? 0 : target)
			scrollView.setContentOffset(point, animated: false)
		} else {
			target = _isHorizontal ? _boundsWidth : _boundsHeight
			let point = CGPoint(x: _isHorizontal ? target : 0, y: _isHorizontal ? 0 : target)
			scrollView.setContentOffset(point, animated: false)
		}

		_displayView.snp.remakeConstraints({ (make) -> Void in
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

		_backupView.snp.remakeConstraints({ (make) -> Void in
			if _isHorizontal {
				if target == _boundsWidth * 2 {
					make.right.equalTo(_displayView.snp.left)
					make.left.equalTo(scrollView).offset(_boundsWidth)
				} else {
					make.left.equalTo(_displayView.snp.right)
					make.right.equalTo(scrollView)
				}
				make.top.bottom.equalTo(scrollView)
			} else {
				make.top.equalTo(_displayView.snp.bottom)
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
		view.backgroundColor = UIColor.white
		initializeSegment()
		initializeScrollview()
		initializeIndicator()
	}

	func initializeScrollview() {

		view.addSubview(scrollView)
		scrollView.addSubview(_displayView)
		scrollView.addSubview(_backupView)

		_displayView.snp.makeConstraints { (make) -> Void in
			make.top.left.bottom.height.width.equalTo(scrollView)
		}
		_backupView.snp.makeConstraints { (make) -> Void in
			make.width.height.equalTo(scrollView)
			if _isHorizontal {
				make.top.bottom.equalTo(scrollView)
				make.left.equalTo(_displayView.snp.right)
				make.right.equalTo(scrollView).offset(-_boundsWidth)
			} else {
				make.left.right.equalTo(scrollView)
				make.top.equalTo(_displayView.snp.bottom)
				make.bottom.equalTo(scrollView).offset(-_boundsHeight)
			}
		}

		scrollView.snp.makeConstraints { (make) -> Void in
			make.top.equalTo(segment.snp.bottom)
			make.left.bottom.right.equalTo(view)
		}
		_isHorizontal ? (scrollView.alwaysBounceHorizontal = true) : (scrollView.alwaysBounceVertical = true)

		let factorX: CGFloat = _isHorizontal ? 3 : 1
		let factorY: CGFloat = _isHorizontal ? 1 : 3
		scrollView.contentSize = CGSize(width: _boundsWidth * factorX, height: _boundsHeight * factorY)
		scrollView.translatesAutoresizingMaskIntoConstraints = false
		scrollView.showsHorizontalScrollIndicator = false
		scrollView.showsVerticalScrollIndicator = false
		scrollView.scrollsToTop = false
		scrollView.backgroundColor = UIColor.white
		scrollView.isPagingEnabled = true
		scrollView.delegate = self
	}
    
    

	func initializeSegment() {
		view.addSubview(segment)
		segment.snp.makeConstraints { (make) -> Void in
			make.top.left.right.equalTo(view)
			make.height.equalTo(0)
		}
	}

	func initializeIndicator() {
		view.addSubview(indicator)
		indicator.isHidden = true
		configureIndicator()
	}

	func configureIndicator() {
		if !_isHorizontal {
			indicator.transform = CGAffineTransform(rotationAngle: CGFloat(M_PI * 90 / 180.0))
		}
		indicator.sizeToFit()
		var inset = UIEdgeInsets.zero
		switch indicatorAlignStyle {
		case .left: _isHorizontal ? (inset.left = 10) : (inset.top = 10)
		case .right: _isHorizontal ? (inset.right = 10) : (inset.bottom = 10)
		default: break
		}
		if _isHorizontal { inset.bottom = 10 }
        else { inset.right = 10 }

		indicator.snp.removeConstraints()
		indicator.snp.makeConstraints { (make) -> Void in
			if _isHorizontal {
				make.bottom.equalTo(inset.bottom)
				if inset.left != 0 { make.left.equalTo(inset.left) }
				if inset.right != 0 { make.right.equalTo(inset.right) }
				if indicatorAlignStyle == .center {
					make.right.left.equalTo(indicator.superview!)
				}
			} else {
				make.right.equalTo(inset.right)
				if inset.top != 0 { make.top.equalTo(inset.top) }
				if inset.bottom != 0 { make.bottom.equalTo(inset.bottom) }
				if indicatorAlignStyle == .center {
					make.top.bottom.equalTo(indicator.superview!)
				}
			}
		}
		UIView.animate(withDuration: 0.2, animations: { () -> Void in
			self.view.setNeedsLayout()
		}) 
	}

	func customConfigurationDone() {
		let hideAndStall = !(_display.ss_nextId == nil && _display.ss_previousId == nil)
        if showsIndicator { indicator.isHidden = hideAndStall }
		scrollView.isScrollEnabled = hideAndStall

		_displayView.snp.removeConstraints()
		_backupView.snp.removeConstraints()

		let hasPrevious = _display.ss_previousId != nil

		_displayView.snp.remakeConstraints { (make) -> Void in
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

		_backupView.snp.remakeConstraints { (make) -> Void in
			make.width.height.equalTo(scrollView)
			if _isHorizontal {
				make.top.bottom.equalTo(scrollView)
				make.left.equalTo(_displayView.snp.right)
				make.right.equalTo(scrollView).offset(hasPrevious ? 0 : -_boundsWidth)
			} else {
				make.left.right.equalTo(scrollView)
				make.top.equalTo(_displayView.snp.bottom)
				make.bottom.equalTo(scrollView).offset(hasPrevious ? 0 : -_boundsHeight)
			}
		}
		let point = hasPrevious ? CGPoint(x: _isHorizontal ? _boundsWidth : 0, y: _isHorizontal ? 0 : _boundsHeight) : CGPoint.zero
		scrollView.setContentOffset(point, animated: false)
		view.setNeedsLayout()
	}

	func addDisplayNextTask() {
		SSCancelableTaskManager.cancel(_task)
		if loopInterval == 0 || (_display.ss_nextId == nil && _display.ss_previousId == nil) { return }
		_task = SSCancelableTaskManager.delay(loopInterval, work: { [weak self]() -> Void in
			guard let sself = self else { return }
			let x = sself._isHorizontal ? sself.scrollView.contentOffset.x + sself._boundsWidth: 0
			let y = sself._isHorizontal ? 0 : sself.scrollView.contentOffset.y + sself._boundsHeight
			sself.scrollView.setContentOffset(CGPoint(x: x, y: y), animated: true)
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
	func pageView(_ pageView: SSPageViewController<Template, Self>, configureForView view: Template, afterView: Template)
	func pageView(_ pageView: SSPageViewController<Template, Self>, configureForView view: Template, beforeView: Template)
	func pageView(_ pageView: SSPageViewController<Template, Self>, didScrollToView view: Template)
}

//MARK:- Help
private extension NSRange {
	func contain(_ number: CGFloat) -> Bool {
		let target = Int(number)
		return location <= target && target <= length
	}
}

//MARK:- CancelableTaskManager
typealias SSCancelableTask = (_ cancel: Bool) -> Void

struct SSCancelableTaskManager {

	static func delay(_ time: TimeInterval, work: @escaping ()->()) -> SSCancelableTask? {

		var finalTask: SSCancelableTask?

		let cancelableTask: SSCancelableTask = { cancel in
			if cancel {
				finalTask = nil // key
			} else {
				DispatchQueue.main.async(execute: work)
			}
		}
		finalTask = cancelableTask
		DispatchQueue.main.asyncAfter(deadline: .now() + time ) {
			if let task = finalTask { task(false) }
		}
		return finalTask
	}

	static func cancel(_ cancelableTask: SSCancelableTask?) {
		cancelableTask?(true)
	}
}
