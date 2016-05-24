//
//  SSImageLooper.swift
//  SSPageView
//
//  Created by LawLincoln on 16/3/15.
//  Copyright © 2016年 CocoaPods. All rights reserved.
//

import UIKit

public final class SSAdBannerManager: NSObject {

	public typealias Template = SSBannerItem

	// MARK:- Public
	public var didShowBannerHandler: ((Int) -> Void)?
	public var didTapBannerHandler: ((Int) -> Void)?
	public var backgroundColor: UIColor? {
		didSet {
			_pageController.view.backgroundColor = backgroundColor
			_pageController.scrollView.backgroundColor = backgroundColor
		}
	}
	public var view: UIView { return _pageController.view }

	public var imageContentMode: UIViewContentMode = .ScaleAspectFit {
		didSet {
			_pageController.initializeTemplateConfiguration = {
				[weak self](display, backup) in
				guard let sself = self else { return }
				display.contentMode = sself.imageContentMode
				backup.contentMode = sself.imageContentMode
			}
		}
	}

	// MARK:- Private
	private lazy var _pageController: SSPageViewController<SSAdBannerManager.Template, SSAdBannerManager> = SSPageViewController(scrollDirection: .Horizontal)
	private lazy var _loopDisplay = true
	private lazy var _map: [Int: String] = [:]
	private lazy var _indexCache: NSCache = NSCache()
	private lazy var _hash = 0

	deinit {
		_pageController.ss_delegate = nil
	}

	public override init() {
		super.init()
		backgroundColor = UIColor.whiteColor()
		_pageController.indicatorAlignStyle = .Center
		_pageController.ss_delegate = self
		_pageController.showsIndicator = true
		_indexCache.countLimit = 10
	}

	public func reset(list: [String], loop: Bool = false) {
		var map = [Int: String]()
		for (index, item) in list.enumerate() {
			map[index] = item
		}
		let canScoll = list.count > 1
		_pageController.indicator.numberOfPages = list.count
		_loopDisplay = canScoll
		_pageController.loopInterval = canScoll ? (loop ? 5 : 0) : 0
		_map = map

		var indicatorIndex = 0
		if list.count > 1 {
			let total = list.joinWithSeparator(",")
			_hash = total.hash
			if let _index = _indexCache.objectForKey(_hash) as? Int {
				indicatorIndex = _index
			} else {
				_indexCache.setObject(0, forKey: _hash)
			}
		}

		_pageController.indicator.currentPage = indicatorIndex
		_pageController.configurationBlock = { [weak self]
			(display, backup) -> Void in
			guard let sself = self else { return }
			backup.image = nil
			display.image = nil
			display.tapBlock = nil
			backup.tapBlock = nil
			backup.configure((url: nil, id: nil, next: nil, previous: nil))
			display.configure((url: nil, id: nil, next: nil, previous: nil))
			let handler: (Int) -> Void = { [weak self]
				index in
				self?.didTapBannerHandler?(index)
			}
			if list.count <= indicatorIndex { return }

			let item = sself.itemAfter(indicatorIndex + 1)
			display.configure(item)
			display.tapBlock = handler
			if list.count <= indicatorIndex + 1 { return }
			let item2 = sself.itemAfter(indicatorIndex + 2)
			backup.configure(item2)
			backup.tapBlock = handler
		}
	}

	public func itemAfter(id: Int, after: Bool = false) -> (String?, Int?, Int?, Int?) {
		if id < 0 { return (nil, nil, nil, nil) }
		let count = _map.count
		var nextId: Int? = nil
		var previousId: Int? = nil
		if count == 1 { return (_map[0], 0, nil, nil) }
		var now: Int?
		if after {
			if id >= count - 1 {
				if _loopDisplay {
					now = 0
				}
			} else {
				now = id + 1
			}
		} else {
			if id == 0 {
				if _loopDisplay {
					now = count - 1
				}
			} else {
				now = id - 1
			}
		}
		guard let nowId = now else { return (nil, now, nextId, previousId) }

		let value = _map[nowId]

		if count == 1 { return (value, now, nextId, previousId) }

		if nowId >= count - 1 {
			if _loopDisplay {
				nextId = 0
			}
		} else {
			nextId = nowId + 1
		}
		if nowId == 0 {
			if _loopDisplay {
				previousId = count - 1
			}
		} else {
			previousId = nowId - 1
		}
		return (value, nowId, nextId, previousId)
	}
}
// MARK: - SSPageViewDelegate
extension SSAdBannerManager: SSPageViewDelegate {

	public func pageView(pageView: SSPageViewController<Template, SSAdBannerManager>, configureForView view: Template, beforeView: Template) {
		guard let value = Int(beforeView.ss_identifer) else { return }
		view.configure(itemAfter(value))
	}

	public func pageView(pageView: SSPageViewController<Template, SSAdBannerManager>, configureForView view: Template, afterView: Template) {
		guard let value = Int(afterView.ss_identifer) else { return }
		view.configure(itemAfter(value, after: true))
	}

	public func pageView(pageView: SSPageViewController<Template, SSAdBannerManager>, didScrollToView view: Template) {
		guard let value = Int(view.ss_identifer) else { return }
		_pageController.indicator.currentPage = value
		if _map.count > 1 {
			_indexCache.setObject(value, forKey: _hash)
		}
		didShowBannerHandler?(value)
	}
}
//MARK:- SSImageLooper
public final class SSBannerItem: UIImageView {

	public typealias DidTapItemClosure = (Int) -> Void

	private var identifer: String?
	private var previousId: String?
	private var nextId: String?
	public var tapBlock: DidTapItemClosure?
	private var _task: NSURLSessionDataTask?

	public convenience init() {
		self.init(frame: CGRectZero)
		layer.backgroundColor = UIColor.lightGrayColor().CGColor
		contentMode = .ScaleAspectFit
		userInteractionEnabled = true
		clipsToBounds = true
		let tap = UITapGestureRecognizer(target: self, action: #selector(SSBannerItem.tap))
		addGestureRecognizer(tap)
	}

	override init(frame: CGRect) {
		super.init(frame: frame)
	}

	required public init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}

	public func configure(con: (url: String?, id: Int?, next: Int?, previous: Int?)) {

		autoreleasepool { () -> () in
			image = nil
			_task?.cancel()
			dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
				if let url = NSURL(string: con.url ?? "") {
					let request = NSMutableURLRequest(URL: url, cachePolicy: .UseProtocolCachePolicy, timeoutInterval: 20)
					self._task = NSURLSession.sharedSession().dataTaskWithRequest(request, completionHandler: { (data, reps, error) in

						guard let data = data, img = UIImage(data: data) else { return }
						dispatch_async(dispatch_get_main_queue(), { [weak self]() -> Void in
							guard let sself = self else { return }
							UIView.transitionWithView(
								sself,
								duration: 0.2,
								options: .TransitionCrossDissolve,
								animations: { [weak self] in
									self?.image = img
								},
								completion: nil
							)
						})
					})
					self._task?.resume()
				}
			})

			identifer = con.id?.string
			nextId = con.next?.string
			previousId = con.previous?.string
		}
	}

	@objc private func tap() {
		guard let idf = identifer, value = Int(idf) else { return }
		tapBlock?(value)
	}
}
// MARK: - SSPageViewContentProtocol
extension SSBannerItem: SSPageViewContentProtocol {
	public var ss_identifer: String {
		return identifer ?? ""
	}
	public var ss_previousId: String? { return previousId }
	public var ss_nextId: String? { return nextId }
	public var ss_content: UIView { return self }
}

extension Int {
	var string: String { return "\(self)" }
}

protocol StringConvertible {
	var ss_string: String { get }
}
extension String: StringConvertible {
	var ss_string: String { return self }
}
